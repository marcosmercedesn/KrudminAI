module KrudminAI
  module IconHelper
    include LucideRails::RailsHelper

    def krudmin_ai_icon(name, **options)
      icon_options = default_icon_options.merge(options)
      icon_options[:class] = [default_icon_options[:class], options[:class]].compact.join(" ")
      lucide_icon(name.to_s.tr("_", "-"), **icon_options)
    end

    private

    def default_icon_options
      { "aria-hidden" => true, class: "krudmin-ai-icon" }
    end
  end
end