# frozen_string_literal: true

module ActiveAdmin
  module SortableTree
    module ControllerActions
      attr_accessor :sortable_options

      def sortable(options = {})
        options.reverse_merge! sorting_attribute: :position,
                               parent_method: :parent,
                               parent_attribute: :parent_id,
                               children_method: :children,
                               roots_method: :roots,
                               tree: false,
                               max_levels: 0,
                               protect_root: false,
                               collapsible: false, # hides +/- buttons
                               start_collapsed: false,
                               sortable: true

        # BAD BAD BAD FIXME: don't pollute original class
        @sortable_options = options

        # disable pagination
        config.paginate = false

        collection_action :sort, method: :post do
          resource_name = ActiveAdmin::SortableTree::Compatibility.normalized_resource_name(active_admin_config.resource_name)

          records = []
          params[resource_name].each_pair do |resource, parent_resource|
            parent_resource = begin
              resource_class.find(parent_resource)
            rescue StandardError
              nil
            end
            records << [resource_class.find(resource), parent_resource]
          end

          errors = []
          ActiveRecord::Base.transaction do
            records.each_with_index do |(record, parent_record), idx|
              prev_elm = idx.zero? ? nil : records[idx - 1]
              next_elm = idx == records.size - 1 ? nil : records[idx + 1]

              if record.root?
                record.move_to_root
              elsif prev_elm
                record.move_to_right_of(prev_elm)
              elsif next_elm
                record.move_to_left_of(next_elm)
              end
              record.move_to_child_of(parent_record) if options[:tree] && parent_record
              errors << { record.id => record.errors } unless record.save
            end
          end
          if errors.empty?
            head 200
          else
            render json: errors, status: 422
          end
        end
      end
    end

    ::ActiveAdmin::ResourceDSL.include ControllerActions
  end
end
