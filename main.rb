require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17

helpers do

  def calc_total(cards)
    arr = cards.map{|element| element[1]}
    total = 0
    arr.each do |a|
      if a == "ace"
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end
    arr.select{|element| element == "ace"}.count.times do
      break if total <= BLACKJACK_AMOUNT
      total -= 10
    end
    total
  end


  def card_image(card)
    #['c', '2']
    if card[0] == 'clubs'
      suit1 = 'clubs_'
    elsif card[0] == 'diamonds'
      suit1 = 'diamonds_'
    elsif card[0] == 'hearts'
      suit1 = 'hearts_'
    elsif card[0] == 'spades'
      suit1 = 'spades_'
    end
    value1 = card[1]
    img_string = ''
    "<img src='/images/cards/#{suit1}#{value1}.jpg' class='card_image'>"
  end

  def winner!(msg)
    @show_hit_or_stay_buttons = false
    @player_turn = false
    @game_over = true
    session[:player_pot] += session[:bet_amount]
    @winner = "<strong>#{session[:player_name]} WINS $#{session[:bet_amount]}!</strong> #{msg} #{session[:player_name]} now has <strong>$#{session[:player_pot]}</strong> to burn."
  end

  def loser!(msg)
    @show_hit_or_stay_buttons = false
    @player_turn = false
    @show_double_down = false
    @game_over = true
    session[:player_pot] -= session[:bet_amount]
    if session[:player_pot] <= 0
      @game_over = false
      @game_over_for_real = true
    end
    @loser = "<strong>#{session[:player_name]} LOSES $#{session[:bet_amount]}!</strong> #{msg} #{session[:player_name]} still has <strong>$#{session[:player_pot]}</strong> left."
  end

  def push!(msg)
    @show_hit_or_stay_buttons = false
    @player_turn = false
    @game_over = true
    @push = "<strong>PUSH!</strong> #{msg} #{session[:player_name]} still has <strong>$#{session[:player_pot]}</strong>."
  end
end




before do   #before filter for logic u need to happen b4 the actions in each request (itc... IV for button wrappers)
  @show_hit_or_stay_buttons = true
  @show_double_down = false
  @dealer_button = false
  @player_turn = true
  @game_over = false
end




get '/' do
  if session[:player_name] # whenever new request, must reestablish previous state using session. "if this exists -> progress to game, otherwise redirect to new player form"
  redirect '/game' #progress to game
  else
    redirect '/new_player'
  end
end


get '/new_player' do
  session[:player_pot] = 10000

  erb :new_player
end


post '/new_player' do
  session[:player_name] = params[:player_name]
  redirect '/bet' # can now progress to the game
  # used to be redirect '/game'
end


get '/bet' do
  #added:
  session[:bet_amount] = nil

  erb :bet

end


post '/bet' do
  if params[:bet_amount].to_i <= session[:player_pot]
    session[:bet_amount] = params[:bet_amount].to_i
    redirect '/game'
  elsif params[:bet_amount].to_i > session[:player_pot]
    @error = "<strong>#{session[:player_name]} does not have that much money. Enter lower bet amount...</strong>"
    halt erb(:bet)
  elsif params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "Must make a bet."
    halt erb(:bet)
    #redirect '/bet'
  end

  #redirect '/game'
end


#[9:00] game == set up initial game values and run template
get '/game' do

  session[:turn] = session[:player_name]

  # create deck and put it in nested array
  suits = ['hearts', 'diamonds', 'clubs', 'spades']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'jack', 'queen', 'king', 'ace']
  session[:deck] = suits.product(values).shuffle! # [['hearts', '2'], ['diamonds', 'ace']...]


  # deal cards
  session[:dealer_cards] = []
  session[:player_cards] = []

  session[:dealer_first] = session[:deck].pop
  session[:dealer_cards] << session[:dealer_first]
  session[:player_first] = session[:deck].pop
  session[:player_cards] << session[:player_first]
  session[:dealer_second] = session[:deck].pop
  session[:dealer_cards] << session[:dealer_second]
  session[:player_second] = session[:deck].pop
  session[:player_cards] << session[:player_second]

  session[:dealer_base] = calc_total(session[:dealer_cards])

  #session[:dealer_cards] << session[:deck].pop
  #first_card = session[:deck].pop
  #session[:player_cards] << first_card
  #session[:dealer_cards] << session[:deck].pop
  #second_card = session[:deck].pop
  #session[:player_cards] << second_card
  

  if calc_total(session[:player_cards]) == BLACKJACK_AMOUNT
    @show_double_down = false
    session[:bet_amount] = session[:bet_amount] * 1.5
    winner!("#{session[:player_name]} hit BLACKJACK!")

  elsif calc_total(session[:dealer_cards]) == BLACKJACK_AMOUNT
    @show_double_down = false
    loser!("Dealer hit BLACKJACK!")
  end
  
  base_hand = calc_total(session[:player_cards])
  if base_hand == 9 || base_hand == 10 || base_hand == 11 || session[:player_first][1] == 'ace' || session[:player_second][1] == 'ace'
    @show_double_down = true
  end

  erb :game
end


post '/game/player/double' do
  session[:bet_amount] += session[:bet_amount]
  session[:player_cards] << session[:deck].pop
  @show_double_down = false

  if calc_total(session[:player_cards]) > BLACKJACK_AMOUNT
    loser!("BUSTED!")
  end

  redirect '/game/dealer'

  erb :game, layout: false
end


post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  @show_double_down = false
  # Don't want to redirect to /game, that would reset the game
  # want to just render the template again...
  if calc_total(session[:player_cards]) > BLACKJACK_AMOUNT
    loser!("BUSTED!")
  end

  erb :game, layout: false    #for AJAX purposes, left w/ just the game element (no more layout... is layout automatically loaded???)
end


post '/game/player/stay' do
  @success = "You have chosen to stay."
  @show_hit_or_stay_buttons = false
  @player_turn = false
  redirect '/game/dealer'

  # erb :game   # COMMENT THIS OUT???
end


get '/game/dealer' do

  session[:turn] = "dealer"

  # show both dealer cards
  @show_hit_or_stay_buttons = false

  dealer_total = calc_total(session[:dealer_cards])
  if dealer_total < DEALER_MIN_HIT
    @dealer_button = true
    @player_turn = false
    # Msg to user saying press the button to deal next dealer card
  elsif dealer_total >= DEALER_MIN_HIT && dealer_total <= BLACKJACK_AMOUNT
    @dealer_button = false
    @player_turn = false
    # Dealer stays at 17 - 21
    # redirect to 'compare' route
    redirect '/game/compare'
  end


  erb :game, layout: false
end


post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  #could've done a redirect '/game/dealer'

  @show_hit_or_stay_buttons = false
  @player_turn = false
  dealer_total = calc_total(session[:dealer_cards])

  if dealer_total >= DEALER_MIN_HIT && dealer_total <= BLACKJACK_AMOUNT
    @dealer_button = false
    #dealer stays...
    #redirect to 'compare' route...
    redirect '/game/compare'
  elsif dealer_total > BLACKJACK_AMOUNT   
    #dealer busts...
    @dealer_button = false
    winner!("#{session[:player_name]} stayed at #{calc_total(session[:player_cards])}, and Dealer BUSTED at #{calc_total(session[:dealer_cards])}.")
  else  
    #dealer hits... display button
    @dealer_button = true
  end

  erb :game, layout: false
end


get '/game/compare' do
  @show_hit_or_stay_buttons = false

  dealer_total = calc_total(session[:dealer_cards])
  player_total = calc_total(session[:player_cards])

  if dealer_total > player_total
    loser!("#{session[:player_name]} stayed at #{calc_total(session[:player_cards])}, and Dealer stayed at #{calc_total(session[:dealer_cards])}.")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{calc_total(session[:player_cards])}, and Dealer stayed at #{calc_total(session[:dealer_cards])}.")
  elsif player_total == dealer_total
    push!("#{session[:player_name]} stayed at #{calc_total(session[:player_cards])}, and Dealer stayed at #{calc_total(session[:dealer_cards])}.")
  end

  erb :game, layout: false
end


get '/game_over' do
  erb :game_over
end

post '/play_again' do
  redirect '/game'
end

get '/player_broke' do
  erb :player_broke
end
