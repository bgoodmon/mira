module AdvancedSearchFields
  extend ActiveSupport::Concern

  included do

    configure_blacklight do |config|

      # Attributes to include in the advanced search form
      adv_search_attrs = TuftsBase.new.terms_for_editing
      already_included_attrs = [:title, :creator, :subject, :batch]
      adv_search_attrs = adv_search_attrs - already_included_attrs

      adv_search_attrs.each do |attr|
        field_name = attr.to_s.underscore
        config.add_search_field(field_name) do |field|
          field.include_in_simple_select = false
          field.solr_local_parameters = { :qf => field_name + '_tesim' }
          # using :format_attr for :format because :format refers to the response
          # format in rails controllers
          if attr == :format
            field.field = "format_attr"
            field.label = "Format"
          end
        end
      end

      # Facets for advanced search form
      config.advanced_search ||= {}
      config.advanced_search[:form_solr_parameters] = {
        "facet.field" => ['names_sim', 'object_type_sim', 'subject_sim', 'year_sim', 'deposit_method_ssi', 'qrStatus_sim'],
        "facet.limit" => -1,     # return all facet values
        "facet.sort" => 'count'
      }
    end  # configure blacklight

  end   # included
end
