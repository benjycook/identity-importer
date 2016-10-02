require 'activerecord-import'

module Identity
  module Importer
    module Tasks
      class Opens

        def self.run
          synced_mailings = Mailing.where(recipients_synced: true)

          synced_mailings.each do |mailing|
            open_events = Identity::Importer.connection.run_query(sql(mailing.external_id))

            opens = []
            ActiveRecord::Base.transaction do
              open_events.each do |open_event|

                member = Member.find_by(email: open_event['email'])
                member_id = member.try(:id) || 1

                member_mailing = MemberMailing.find_by(member_id: member_id, mailing_id: mailing.id)

                open = Open.new(
                  member_mailing_id: member_mailing.id
                )

                timestamp = open_event['timestamp'].to_datetime
                open.created_at = timestamp
                open.updated_at = timestamp

                if member_mailing.first_opened.nil?
                  member_mailing.first_opened = timestamp
                  member_mailing.save!
                end

                opens << open
              end
              Open.import opens
            end

            mailing.update_counts
          end
        end

      end
    end
  end
end