# Service that deposits data in Zenodo.org
class ZenodoDepositor
  attr_accessor :user_log

  def initialize(deposition)
    @deposition = deposition
    @user_log = []
  end

  # 1. Sets up a new deposition in Zenodo, with proper metadata
  # 2. Uploads CSV data to that deposition
  # 3. Publishes that deposition (i.e. makes it available to Zenodo users)
  def call
    unless @deposition && @deposition.valid?
      report_problem 'Got nil or invalid Deposition. Unable to upload it to Zenodo.'
      return
    end

    documents_to_deposit = @deposition.documents_to_deposit
    if documents_to_deposit.empty?
      report_problem 'Nothing to deposit in Zenodo - deposition documents empty.'
      return
    end

    request = Typhoeus::Request.new(
      query_url,
      method: :post,
      headers: { 'Content-Type' => 'application/json' },
      body: {
        metadata: {
          upload_type: 'dataset',
          title: @deposition.title,
          creators: @deposition.creators,
          description: @deposition.description
        }
      }.to_json
    )

    submit_request(request) do |response|
      puts response.body
      remote_deposition = JSON.parse(response.body)

      documents_to_deposit.each do |name, contents|
        next if contents.empty?
        request = Typhoeus::Request.new(
            query_url("/#{remote_deposition['id']}/files"),
            method: :post,
            headers: { 'Content-Type' => 'multipart/form-data' },
            body: {
                filename: "#{name}.csv",
                file: write_file(contents, "#{name}.csv")
                # file: File.open(Rails.root + 'Gemfile', 'r')
                # file: StringIO.new("header1,header2\nvalue1,value2")
            }
        )
        submit_request(request) do |response|
          puts response.body
        end
      end

      # TODO FIXME just a temporary generated DOI, implement actual Zenodo client later
      # doi = '10.5194/bg-8-2917-2011'
      # if @deposition.submission
      #   @deposition.submission.doi = doi
      #   @deposition.submission.save!
      # end
    end
  end

  private

  def write_file(contents, filename)
    file = Tempfile.new(filename)
    # file.path      # => A unique filename in the OS's temp directory,
    #                #    e.g.: "/tmp/foo.24722.0"
    #                #    This filename contains 'foo' in its basename.
    file.write contents
    file.rewind
    file
    # file.read      # => "hello world"
    # file.close
    # file.unlink    # deletes the temp file
    # file
  end

  def submit_request(request)
    request.on_complete do |response|
      if response.success?
        yield response
      elsif response.timed_out?
        report_problem 'Zenodo service does not respond. Unable to deposit data.', true
      elsif response.code == 0
        report_problem 'Zenodo service responded with invalid content. Unable to conclude data deposition.', true
      else
        Rails.logger.tagged(self.class.name) do
          Rails.logger.info response.body
        end
        report_problem "Zenodo service responded with failure code #{response.code}. Unable to conclude data deposition.", true
      end
    end

    request.run
  end

  def query_url(resource = '')
    host = Rails.application.config_for(:zenodo)['zenodo_server']
    key = Rails.application.secrets.zenodo_key
    "#{host}api/deposit/depositions#{resource}?access_token=#{key}"
  end

  def report_problem(message, to_user = false)
    Rails.logger.tagged(self.class.name) do
      Rails.logger.warn message
    end
    @user_log << message if to_user
  end
end
