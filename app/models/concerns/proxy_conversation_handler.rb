module ProxyConversationHandler
  extend ActiveSupport::Concern

  included do
    after_update_commit :close_linked_widget_conversation_if_resolved
  end

  private

  def close_linked_widget_conversation_if_resolved
    return unless saved_change_to_status?
    return unless resolved?

    linked_id = additional_attributes&.dig('linked_conversation_id')
    return if linked_id.blank?

    widget_conv = Conversation.find_by(id: linked_id, status: :proxied)
    return if widget_conv.blank?
    return unless widget_conv.inbox.channel_type == 'Channel::WebWidget'

    widget_conv.resolved!
  rescue StandardError => e
    Rails.logger.error("ProxyConversationHandler: failed to close widget conversation: #{e.message}")
  end
end
