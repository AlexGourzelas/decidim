# frozen_string_literal: true

module Decidim
  module Meetings
    module Admin
      # This command is executed when the user changes a Meeting from the admin
      # panel.
      class UpdateMeeting < Rectify::Command
        # Initializes a UpdateMeeting Command.
        #
        # form - The form from which to get the data.
        # meeting - The current instance of the page to be updated.
        def initialize(form, meeting)
          @form = form
          @meeting = meeting
        end

        # Updates the meeting if valid.
        #
        # Broadcasts :ok if successful, :invalid otherwise.
        def call
          return broadcast(:invalid) if form.invalid?

          transaction do
            update_meeting!
            send_notification if should_notify_followers?
            schedule_upcoming_meeting_notification if meeting.published? && start_time_changed?
            update_services!
          end

          broadcast(:ok, meeting)
        end

        private

        attr_reader :form, :meeting

        def update_meeting!
          parsed_title = Decidim::ContentProcessor.parse_with_processor(:hashtag, form.title, current_organization: form.current_organization).rewrite
          parsed_description = Decidim::ContentProcessor.parse_with_processor(:hashtag, form.description, current_organization: form.current_organization).rewrite

          Decidim.traceability.update!(
            meeting,
            form.current_user,
            scope: form.scope,
            category: form.category,
            title: parsed_title,
            description: parsed_description,
            end_time: form.end_time,
            start_time: form.start_time,
            online_meeting_url: form.online_meeting_url,
            registration_type: form.registration_type,
            registration_url: form.registration_url,
            available_slots: form.available_slots,
            type_of_meeting: form.clean_type_of_meeting,
            address: form.address,
            latitude: form.latitude,
            longitude: form.longitude,
            location: form.location,
            location_hints: form.location_hints,
            private_meeting: form.private_meeting,
            transparent: form.transparent,
            customize_registration_email: form.customize_registration_email,
            registration_email_custom_content: form.registration_email_custom_content,
            show_embedded_iframe: form.show_embedded_iframe,
            comments_enabled: form.comments_enabled,
            comments_start_time: form.comments_start_time,
            comments_end_time: form.comments_end_time
          )
        end

        def update_services!
          meeting.services = form.services_to_persist.map do |service|
            Decidim::Meetings::Service.new("title" => service.title, "description" => service.description)
          end
          meeting.save!
        end

        def send_notification
          Decidim::EventsManager.publish(
            event: "decidim.events.meetings.meeting_updated",
            event_class: Decidim::Meetings::UpdateMeetingEvent,
            resource: meeting,
            followers: meeting.followers
          )
        end

        def should_notify_followers?
          meeting.published? && important_attributes.any? { |attr| meeting.previous_changes[attr].present? }
        end

        def important_attributes
          %w(start_time end_time address)
        end

        def start_time_changed?
          meeting.previous_changes["start_time"].present?
        end

        def schedule_upcoming_meeting_notification
          checksum = Decidim::Meetings::UpcomingMeetingNotificationJob.generate_checksum(meeting)

          Decidim::Meetings::UpcomingMeetingNotificationJob
            .set(wait_until: meeting.start_time - 2.days)
            .perform_later(meeting.id, checksum)
        end
      end
    end
  end
end
