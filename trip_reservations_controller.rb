class TripReservationsController < ApplicationController def create
  reservation = TripReservation.new(params[:trip_reservation])
  trip = Trip.find_by_id(reservation.trip_id)
  agency = trip.agency
  payment_adapter = PaymentAdapter.new(buyer: current_user)
  unless current_user.can_book_from?(agency)
    redirect_to trip_reservations_page, notice: "You're not allowed to book from this agency."
  end
  unless trip.has_free_tickets?
    redirect_to trip_reservations_page, notice: "No free tickets available"
  end
  begin
    receipt = payment_adapter.pay(trip.price)
    reservation.receipt_id = receipt.uuid
    unless reservation.save
      logger.info "Failed to save reservation: #{reservation.errors.inspect}" redirect_to trip_reservations_page, notice: "Reservation error."
    end
    redirect_to trip_reservations_page(reservation), notice: "Thank your for your reservation!" rescue PaymentError
    logger.info "User #{current_user.name} failed to pay for a trip #{trip.name}: #{$!.message}"
    redirect_to trip_reservations_page, notice: "Payment error."
  end
end
end
