class ReservationMailer < InstanceMailer
  layout 'mailer'

  def notify_guest_of_cancellation(reservation)
    setup_defaults(reservation)
    generate_mail('A booking you made has been cancelled by the owner')
  end

  def notify_guest_of_confirmation(reservation)
    setup_defaults(reservation)
    generate_mail('A booking you made has been confirmed')
  end

  def notify_guest_of_rejection(reservation)
    setup_defaults(reservation)
    generate_mail("A booking you made has been declined")
  end

  def notify_guest_with_confirmation(reservation)
    setup_defaults(reservation)
    generate_mail('A booking you made is pending confirmation')
  end

  def notify_host_of_cancellation(reservation)
    setup_defaults(reservation)
    @user = @listing.contact_person
    set_bcc_email
    generate_mail('A guest has cancelled a booking')
  end

  def notify_host_of_confirmation(reservation)
    setup_defaults(reservation)
    @user = @listing.contact_person
    set_bcc_email
    generate_mail('You have confirmed a booking')
  end

  def notify_guest_of_expiration(reservation)
    setup_defaults(reservation)
    generate_mail('A booking you made has expired')
  end
  
  def notify_host_of_expiration(reservation)
    setup_defaults(reservation)
    @user = @listing.contact_person
    set_bcc_email
    generate_mail('A booking for one of your listings has expired')
  end
  
  def notify_host_with_confirmation(reservation)
    setup_defaults(reservation)
    @user = @listing.contact_person
    set_bcc_email
    @url  = manage_guests_dashboard_url(:token => @user.authentication_token)
    generate_mail('A booking requires your confirmation')
  end

  def notify_host_without_confirmation(reservation)
    setup_defaults(reservation)
    @user = @listing.contact_person
    set_bcc_email
    @url  = manage_guests_dashboard_url(:token => @user.authentication_token)
    @reserver = @reservation.owner.name
    generate_mail('A guest has made a booking')
  end

  if defined? MailView
    class Preview < MailView

      def notify_guest_of_cancellation
        ::ReservationMailer.notify_guest_of_cancellation(reservation)
      end

      def notify_guest_of_confirmation
        ::ReservationMailer.notify_guest_of_confirmation(reservation)
      end

      def notify_guest_of_expiration
        ::ReservationMailer.notify_guest_of_expiration(reservation)
      end

      def notify_guest_of_rejection
       ::ReservationMailer.notify_guest_of_rejection(reservation)
      end

      def notify_guest_with_confirmation
        ::ReservationMailer.notify_guest_with_confirmation(reservation)
      end

      def notify_host_of_cancellation
        ::ReservationMailer.notify_host_of_cancellation(reservation)
      end

      def notify_host_of_confirmation
        ::ReservationMailer.notify_host_of_confirmation(reservation)
      end

      def notify_host_of_expiration
        ::ReservationMailer.notify_host_of_expiration(reservation)
      end

      def notify_host_with_confirmation
        ::ReservationMailer.notify_host_with_confirmation(reservation)
      end

      def notify_host_without_confirmation
        ::ReservationMailer.notify_host_without_confirmation(reservation)
      end

      private

        def reservation
          Reservation.last || FactoryGirl.create(:reservation)
        end

    end
  end

  private

  def setup_defaults(reservation)
    @reservation  = reservation
    @listing      = @reservation.listing.reload
    @user         = @reservation.owner
    @host = @reservation.listing.contact_person
    @theme = @listing.instance.theme
  end

  def generate_mail(subject)
    @bcc ||= @theme.contact_email

    mail(to: @user.email,
         theme: @theme,
         bcc: @bcc,
         subject: instance_prefix(subject, @listing.instance))
  end

  def set_bcc_email
    @bcc = [@theme.contact_email, @listing.location.email].uniq if @listing.location.email != @listing.contact_person.email
  end

end
