class CounterOfferAPI
  include Base

  authenticate :show, :accept, :decline

  def show
    counter_offer = Higgle.find(params['higgle_id']).counter_offer
    render(counter_offer, 'counter_offers/show')
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def accept
    counter_offer = CounterOffer.find(params['counter_offer_id'])
    order = counter_offer.higgle.order_for(current_user)
    OrderTransaction.accept_counter_offer!(counter_offer, order, false)
    responds('ok')
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def decline
    counter_offer = CounterOffer.find(params['counter_offer_id'])
    counter_offer.decline!(current_user)
    responds('ok')
  rescue ActiveRecord::RecordNotFound
    not_found
  end
end
