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

        @sortable_options = options

        config.paginate = false

        collection_action :sort, method: :post do
          errors = []
          ActiveRecord::Base.transaction do
            id = params[:id].to_i
            parent_id = params[:parent_id].to_i
            prev_id   = params[:prev_id].to_i
            next_id   = params[:next_id].to_i

            return head_respond(:no_content) if parent_id.zero? && prev_id.zero? && next_id.zero?

            record = resource_class.find(id)

            if prev_id.zero? && next_id.zero?
              record.move_to_child_of resource_class.find(parent_id)
            elsif !prev_id.zero?
              record.move_to_right_of resource_class.find(prev_id)
            elsif !next_id.zero?
              record.move_to_left_of resource_class.find(next_id)
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
