# frozen_string_literal: true

class AuditEventPresenter < Gitlab::View::Presenter::Simple
  presents :audit_event

  def author_name
    author&.name
  end

  def author_url
    return if author.is_a?(Gitlab::Audit::NullAuthor)

    url_for(user_path(author))
  end

  def target
    details[:target_details]
  end

  def ip_address
    details[:ip_address]
  end

  def details
    audit_event.details
  end

  def object
    return if entity.is_a?(Gitlab::Audit::NullEntity)

    details[:entity_path] || entity.name
  end

  def object_url
    return if entity.is_a?(Gitlab::Audit::NullEntity)

    url_for(entity)
  end

  def date
    audit_event.created_at.to_s(:db)
  end

  def action
    Audit::Details.humanize(details)
  end

  private

  def author
    @author ||= audit_event.lazy_author
  end

  def entity
    @entity ||= audit_event.lazy_entity
  end
end
