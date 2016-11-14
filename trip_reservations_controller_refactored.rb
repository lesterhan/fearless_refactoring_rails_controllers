class TripReservationsController < ApplicationController

  def create
    begin
      TripReservationService.new(logger).execute(current_user, params[:trip_reservation])
      redirect_to trip_reservations_page(reservation), notice: "Thank your for your reservation!"
    rescue TripReservationService::NotAllowedToBook
      redirect_to trip_reservations_page, notice: "You're not allowed to book from this agency."
    rescue TripReservationService::NoTicketsAvailable
      redirect_to trip_reservations_page, notice: "No free tickets available"
    rescue TripReservationService::ReservationError
      redirect_to trip_reservations_page, notice: "Reservation error."
    rescue TripReservationService::PaymentProblem
      redirect_to trip_reservations_page, notice: "Payment error."
    end

  end

  class TripReservationService

    attr_reader :logger

    class NotAllowedToBook < StandardError;
    end
    class NoTicketsAvailable < StandardError;
    end
    class ReservationError < StandardError;
    end
    class PaymentProblem < StandardError;
    end

    def initialize(logger)
      @logger = logger
    end

    def execute(current_user, trip_reservation_param)
      reservation = TripReservation.new(trip_reservation_param)
      trip = Trip.find_by_id(reservation.trip_id)
      agency = trip.agency
      payment_adapter = PaymentAdapter.new(buyer: current_user)

      raise NotAllowedToBook.new unless current_user.can_book_from?(agency)
      raise NoTicketsAvailable.new unless trip.has_free_tickets?

      begin
        receipt = payment_adapter.pay(trip.price)
        reservation.receipt_id = receipt.uuid

        unless reservation.save
          @logger.info "Failed to save reservation: #{reservation.errors.inspect}"
          raise ReservationError.new
        end
      rescue PaymentError
        @logger.info "User #{current_user.name} failed to pay for a trip #{trip.name}: #{$!.message}"
        raise PaymentProblem.new
      end
    end

  end

end
