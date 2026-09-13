require "krudmin_ai/fields/belongs_to"

module KrudminAI
  module Fields
    class RemoteBelongsTo < BelongsTo
      DEFAULT_MINIMUM_QUERY_LENGTH = 2
      DEFAULT_PER_PAGE = 20
      MAXIMUM_PER_PAGE = 100

      def remote? = true

      def selected_label(record, context)
        label_for(association_value(record), context)
      end

      def minimum_query_length
        Integer(options.fetch(:minimum_query_length, DEFAULT_MINIMUM_QUERY_LENGTH), exception: false)&.clamp(1, 100) || DEFAULT_MINIMUM_QUERY_LENGTH
      end

      def per_page
        Integer(options.fetch(:per_page, DEFAULT_PER_PAGE), exception: false)&.clamp(1, MAXIMUM_PER_PAGE) || DEFAULT_PER_PAGE
      end

      def lookup_results(query:, page:, context:, authorization_provider: nil)
        return { results: [], more: false } if query.to_s.strip.length < minimum_query_length

        candidates = protected_collection(context, authorization_provider:)
          .where("#{target_resource.model_class.connection.quote_column_name(options.fetch(:label, :name))} LIKE ?", "%#{sanitize_query(query)}%")
          .limit(per_page + 1)
          .offset((page - 1) * per_page)
          .to_a
        more = candidates.length > per_page
        { results: candidates.first(per_page).filter_map { |candidate| { id: candidate.id, label: label_for(candidate, context) } if label_readable?(candidate, context) }, more: }
      end

      private

      def sanitize_query(query)
        query.to_s.strip.gsub("\\", "\\\\").gsub("%", "\\%").gsub("_", "\\_")
      end
    end
  end
end
