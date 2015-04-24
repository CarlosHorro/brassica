module DataTablesHelper
  def datatables_source
    data_tables_path(
      query: params[:query],
      model: model_param
    )
  end

  def datatable_tag
    content_tag(
      :table,
      class: 'table table-condensed data-table',
      id: model_param.dasherize,
      data: { ajax: datatables_source }
    ) do
      content_tag(:thead) do
        content_tag(:tr) do
          yield
        end
      end
    end
  end

  def active_tab_label
    case model_param
      when 'plant_populations', 'plant_lines', 'plant_varieties'
        :plant_populations
      when 'plant_trials', 'trait_descriptors', 'trait_scores'
        :trait_descriptors
      when 'linkage_maps'
        :linkage_maps
      when 'qtl'
        :qtl
      else
        :plant_populations
    end
  end

  def tab_link(label, path)
    active = active_tab_label == label
    html_class = active ? 'active' : ''
    content_tag :li, role: 'presentation', class: html_class do
      link_to t("browse_tabs.#{label}"), active ? '#' : path
    end
  end

  def browse_tabs
    {
      plant_populations: data_tables_path(model: :plant_populations),
      trait_descriptors: data_tables_path(model: :trait_descriptors, group: true),
      linkage_maps: data_tables_path(model: :linkage_maps),
      qtl: data_tables_path(model: :qtl, group: true)
    }
  end

  def back_button
    unless browse_tabs.keys.include? model_param.to_sym
      label = "Back to #{active_tab_label.to_s.humanize}"
      link_to label,
              browse_tabs[active_tab_label],
              id: 'table-back-button',
              data: { label: label },
              class: 'hidden'
    end
  end

  def model_param
    if params[:model].present?
      params[:model]
    else
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  # Returns [model_table_name, column_name] pair
  def extract_column(column_string)
    column_string.match(/\(([^\)]+)\)/) do |match|
      column_string = match[0][1..-2]  # remove aggregation function
    end

    column_string = column_string.
      to_s.                            # make sure it IS a string
      split(/ as /i)[-1]               # honor aliasing

    column_string.gsub!('_count','')   # support cached count columns as well

    if column_string.include? '.'
      column_string.split '.'
    else
      [model_param, column_string]
    end
  end
end
