module MessageWidgetProxy
  extend ActiveSupport::Concern

  included do
    after_create_commit :mirror_outgoing_to_linked_widget_conversation
  end

  private

  def mirror_outgoing_to_linked_widget_conversation
    return unless outgoing?
    return unless sender.is_a?(User)
    return if Thread.current[:mirroring_widget_message]

    widget_conversation = find_widget_conversation_linked_to(conversation)
    return if widget_conversation.blank?
    return if content.blank? && attachments.empty?

    Thread.current[:mirroring_widget_message] = true

    params = {
      content: content,
      message_type: 'outgoing',
      source_id: nil
    }

    mirrored = Messages::MessageBuilder.new(sender, widget_conversation, params).perform

    attachments.each do |original_attachment|
      next unless original_attachment.file.attached?

      new_att = mirrored.attachments.create!(
        account_id: mirrored.account_id,
        file_type: original_attachment.file_type
      )
      new_att.file.attach(original_attachment.file.blob)
      new_att.save!
    rescue StandardError => e
      Rails.logger.error("MessageWidgetProxy: failed to mirror attachment: #{e.message}")
    end
  rescue StandardError => e
    Rails.logger.error(
      "MessageWidgetProxy mirror_outgoing_to_linked_widget_conversation failed: #{e.class} - #{e.message}"
    )
  ensure
    Thread.current[:mirroring_widget_message] = nil
  end

  def find_widget_conversation_linked_to(source_conversation)
    attrs = source_conversation.additional_attributes || {}

    linked_id = attrs['linked_conversation_id']
    return nil if linked_id.blank?

    linked = Conversation.find_by(id: linked_id)
    return nil if linked.blank?

    return linked if linked.inbox.channel_type == 'Channel::WebWidget'

    nil
  end
end
