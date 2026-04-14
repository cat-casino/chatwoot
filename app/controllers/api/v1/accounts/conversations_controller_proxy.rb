module Api::V1::Accounts::ConversationsControllerProxy
  def change_inbox
    widget_conversation = find_and_authorize_conversation
    target_inbox = find_and_authorize_inbox

    operator_conversation = transfer_conversation(widget_conversation, target_inbox)

    render json: build_response(target_inbox, operator_conversation)
  rescue StandardError => e
    Rails.logger.error("ConversationsControllerProxy#change_inbox failed: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    render json: { error: 'Could not change inbox' }, status: :unprocessable_entity
  end

  private

  def find_and_authorize_conversation
    conversation = Current.account.conversations.find_by!(display_id: params[:id])
    authorize conversation, :update?
    conversation
  end

  def find_and_authorize_inbox
    inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize inbox, :index_all?
    inbox
  end

  def transfer_conversation(widget_conversation, target_inbox)
    operator_conversation = nil

    ActiveRecord::Base.transaction do
      contact_inbox = find_or_create_contact_inbox(widget_conversation.contact, target_inbox)
      operator_conversation = create_operator_conversation(widget_conversation, target_inbox, contact_inbox)
      link_conversations(widget_conversation, operator_conversation)
      widget_conversation.update!(status: :proxied)
    end

    copy_message_history(widget_conversation, operator_conversation)

    operator_conversation
  end

  def create_operator_conversation(widget_conversation, target_inbox, contact_inbox)
    Conversation.create!(
      account: widget_conversation.account,
      inbox: target_inbox,
      contact: widget_conversation.contact,
      contact_inbox: contact_inbox,
      additional_attributes: merged_attributes(widget_conversation, widget_conversation.id),
      custom_attributes: widget_conversation.custom_attributes
    )
  end

  def link_conversations(widget_conversation, operator_conversation)
    widget_conversation.update!(
      additional_attributes: merged_attributes(widget_conversation, operator_conversation.id)
    )
  end

  def merged_attributes(conversation, linked_id)
    (conversation.additional_attributes || {}).merge('linked_conversation_id' => linked_id)
  end

  def copy_message_history(source_conversation, target_conversation)
    source_conversation.messages.chat.order(:created_at).each do |message|
      next if message.content.blank? && message.attachments.empty?
      next if target_conversation.messages.exists?(source_id: "history_#{message.id}")

      is_private = message.outgoing?

      mirrored = target_conversation.messages.new(
        account_id: target_conversation.account_id,
        inbox_id: target_conversation.inbox_id,
        message_type: is_private ? :activity : message.message_type,
        content: message.content,
        sender: message.sender,
        private: is_private,
        source_id: "history_#{message.id}"
      )
      mirrored.save!(validate: false)
      mirrored.update_column(:created_at, message.created_at)

      message.attachments.each do |attachment|
        next unless attachment.file.attached?

        new_att = mirrored.attachments.create!(
          account_id: mirrored.account_id,
          file_type: attachment.file_type
        )
        new_att.file.attach(attachment.file.blob)
        new_att.save!
      rescue StandardError => e
        Rails.logger.error("copy_message_history: failed to mirror attachment #{attachment.id}: #{e.message}")
      end

      mirrored.reload

      Rails.configuration.dispatcher.dispatch(
        Events::Types::MESSAGE_CREATED,
        Time.zone.now,
        message: mirrored,
        performed_by: nil
      )
    rescue StandardError => e
      Rails.logger.error("copy_message_history: failed to mirror message #{message.id}: #{e.message}")
    end
  end

  def build_response(inbox, _operator_conversation)
    {
      success: true,
      inbox_id: inbox.id,
      website_token: inbox.channel.respond_to?(:website_token) ? inbox.channel.website_token : nil
    }
  end

  def find_or_create_contact_inbox(contact, inbox)
    existing = ContactInbox.find_by(contact: contact, inbox: inbox)
    return existing if existing

    ci = ContactInboxBuilder.new(contact: contact, inbox: inbox, source_id: SecureRandom.uuid).perform

    unless ci
      ci = ContactInbox.find_by(contact: contact, inbox: inbox)
      return ci if ci

      ci = ContactInbox.new(contact: contact, inbox: inbox, source_id: SecureRandom.uuid)
      ci.save(validate: false)
    end

    ci
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("find_or_create_contact_inbox: validation failed (#{e.message}), falling back to find")
    ContactInbox.find_by(contact: contact, inbox: inbox)
  end
end
