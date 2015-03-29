class SubmissionsController < ApplicationController

  before_filter :authenticate_user!, except: :new

  def index
    @submissions = current_user.submissions
  end

  def show
    submission = current_user.submissions.find(params[:id])
    @submission = PlantPopulationSubmissionDecorator.decorate(submission)
  end

  def edit
    @submission = current_user.submissions.find(params[:id])
    @content = step_content_form(@submission.step, @submission.content[@submission.step])
  end

  def new
  end

  def create
    submission = current_user.submissions.create!(submission_create_params)
    redirect_to edit_submission_path(submission)
  end

  def update
    @submission = current_user.submissions.find(params[:id])
    @content = step_content_form(@submission.step)

    if params[:back]
      @submission.step_back
      redirect_to edit_submission_path(@submission) and return
    end

    unless @content.valid?
      render action: :edit and return
    end

    @content.save do |step_attrs|
      @submission.content.update(@submission.step, step_attrs)
    end

    if @submission.last_step?
      @submission.finalize
      redirect_to submission_path(@submission), notice: "Plant population submitted, thank you!"
    else
      @submission.step_forward
      redirect_to edit_submission_path(@submission)
    end
  end

  def destroy
    submission = current_user.submissions.find(params[:id])
    submission.destroy
    redirect_to submissions_path, notice: "Submission deleted"
  end

  private

  def step_content_form(step, step_content_params = nil)
    klass_name = "Submissions::#{step.to_s.classify}ContentForm"
    klass = klass_name.constantize
    step_content_params ||= submission_content_params.permit(klass.permitted_properties)
    klass.new(Hashie::Mash.new(step_content_params || {}))
  end

  def submission_params
    params.require(:submission)
  end

  # Allow setting submission_type only on create
  def submission_create_params
    params.require(:submission).permit(:submission_type)
  end

  def submission_content_params
    submission_params.require(:content)
  end
end
