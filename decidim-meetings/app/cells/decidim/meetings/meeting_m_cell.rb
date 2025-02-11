# frozen_string_literal: true

module Decidim
  module Meetings
    # This cell renders the Medium (:m) meeting card
    # for an given instance of a Meeting
    class MeetingMCell < Decidim::CardMCell
      include MeetingCellsHelper

      def has_authors?
        true
      end

      def render_authorship
        cell "decidim/author", author_presenter_for(model.normalized_author)
      end

      def date
        render
      end

      def address
        decidim_html_escape(render)
      end

      def title
        present(model).title
      end

      def badge
        render if has_badge?
      end

      def has_badge?
        withdrawn?
      end

      def state_classes
        ["alert"]
      end

      delegate :online_meeting?, to: :model

      private

      def has_state?
        withdrawn?
      end

      def resource_image_path
        model.photo&.url
      end

      def has_image?
        true
      end

      def spans_multiple_dates?
        start_date != end_date
      end

      def meeting_date
        return render(:multiple_dates) if spans_multiple_dates?

        render(:single_date)
      end

      def formatted_start_time
        model.start_time.strftime("%H:%M")
      end

      def formatted_end_time
        model.end_time.strftime("%H:%M")
      end

      def start_date
        model.start_time.to_date
      end

      def end_date
        model.end_time.to_date
      end

      def can_join?
        model.can_be_joined_by?(current_user)
      end

      def show_footer_actions?
        options[:show_footer_actions]
      end

      def statuses
        [:follow, :comments_count]
      end
    end
  end
end
