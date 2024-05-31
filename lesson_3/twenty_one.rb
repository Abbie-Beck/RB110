require 'yaml'

MESSAGES = YAML.load_file('twenty_one_messages.yml')
SUITS = ['H', 'D', 'S', 'C']
VALUES = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
WINNING_SCORE = 5
ROUND_LIMIT = 21
DEALER_STAY = 17

# game methods

def messages(message)
  MESSAGES[message]
end

def prompt(msg)
  puts "=> #{msg}"
end

def initialize_deck
  SUITS.product(VALUES).shuffle
end

def clear_screen
  (system 'clear') || (system 'cls')
end


def aces(score)
  score + 11
end

def current_total(cards)
  nums = cards.map { |card| card[1] }

  score = 0
  nums.each do |num|
    if num == "A"
      score = aces(score)
    elsif num.to_i == 0
      score += 10
    else
      score += num.to_i
    end
  end

  nums.select { |num| num == "A" }.count.times do
    score -= 10 if score > ROUND_LIMIT
  end

  score
end

def busted?(cards)
  cards > ROUND_LIMIT
end

def who_wins(dealer_total, player_total)
  if player_total > ROUND_LIMIT
    :player_busted
  elsif dealer_total > ROUND_LIMIT
    :dealer_busted
  elsif dealer_total < player_total
    :player
  elsif dealer_total > player_total
    :dealer
  else
    :tie
  end
end

def display_result(dealer_total, player_total)
  result = who_wins(dealer_total, player_total)

  case result
  when :player_busted
    prompt(messages('player_busted'))
  when :dealer_busted
    prompt(messages('dealer_busted'))
  when :player
    prompt(messages('player_wins'))
  when :dealer
    prompt(messages('dealer_wins'))
  when :tie
    prompt(messages('tie'))
  end
end

def keeping_score(winner, scores)
  case winner
  when :player, :dealer_busted
    scores[:player_score] += 1
  when :dealer, :player_busted
    scores[:dealer_score] += 1
  when :tie
    scores[:ties] += 1
  end
end

def initial_deal(player_cards, dealer_cards, deck)
  2.times do
    player_cards << deck.pop
    dealer_cards << deck.pop
  end

  prompt format(messages('dealer_cards'), dealer: dealer_cards[0])
  prompt format(messages('player_cards'), cards1: player_cards[0],
                                          cards2: player_cards[1],
                                          total: current_total(player_cards))
end

def prompt_ask_name
  loop do
    prompt(messages('welcome'))
    name = gets.chomp.strip.capitalize

    return name unless name.strip.empty?

    prompt(messages('valid_name'))
  end
  name
end

def display_greeting
  name = prompt_ask_name
  prompt format(messages('greeting_name'), name: name)
end

def show_rules?
  prompt(messages('need_rules'))
  answer = gets.chomp.downcase
  clear_screen
  answer.start_with?('y')
end

def rules_info
  loop do
    prompt(messages('rules'))
    prompt(messages('type_to_exit'))

    answer = gets.chomp.downcase
    break if answer.include?('y')
  end
end

def display_rules
  rules_info if show_rules?
end

# player

def player_turn_loop(player_cards, deck, player_total)
  loop do
    player_turn = return_player_choice
    player_hits(player_cards, deck) if player_turn == 'h'

    player_total = current_total(player_cards)

    break if player_turn_break?(player_turn, player_total)
  end
  player_total
end

def prompt_player
  prompt(messages('hit_or_stay'))
  gets.chomp.downcase
end

def player_busts(dealer_total, player_total, dealer_cards, player_cards, scores)
  display_compare(dealer_total, player_total, dealer_cards, player_cards)
  keeping_score(who_wins(dealer_total, player_total), scores)
  display_score(scores)
end

def return_player_choice
  loop do
    player_turn = prompt_player
    return player_turn if %w(h s).include?(player_turn)
    prompt(messages('valid_move'))
  end
end

def player_hits(player_cards, deck)
  player_cards << deck.pop
  prompt(messages('player_hit'))
  prompt format(messages('player_cards_update'), cards: player_cards)
  prompt format(messages('player_total'), total: current_total(player_cards))
end

def player_turn_break?(player_turn, player_total)
  player_turn == 's' || busted?(player_total)
end

# dealer

def dealer_turn_loop(dealer_cards, deck, dealer_total)
  loop do
    sleep 1
    break if current_total(dealer_cards) >= DEALER_STAY

    prompt(messages('dealer_hits'))
    dealer_cards << deck.pop
    dealer_total = current_total(dealer_cards)
    prompt format(messages('dealer_cards_update'), cards: dealer_cards)
  end
  dealer_total
end

def dealer_busts(dealer_total, player_total, dealer_cards, player_cards, scores)
  display_dealer_bust(dealer_total, player_total, dealer_cards, player_cards)
  keeping_score(who_wins(dealer_total, player_total), scores)
  display_score(scores)
end

def display_dealer_bust(dealer_total, player_total, dealer_cards, player_cards)
  prompt format(messages('dealer_total'), total: dealer_total)
  display_compare(dealer_total, player_total, dealer_cards, player_cards)
end

# game play

def compare_cards(dealer_cards, player_cards, dealer_total, player_total)
  puts messages('bar')
  prompt format(messages('deal_score'), card: dealer_cards, total: dealer_total)
  prompt format(messages('play_score'), card: player_cards, total: player_total)
  puts messages('bar')
end

def display_compare(dealer_total, player_total, dealer_cards, player_cards)
  compare_cards(dealer_cards, player_cards, dealer_total, player_total)
  display_result(dealer_total, player_total)
end

def nobody_busts(dealer_total, player_total, dealer_cards, player_cards, scores)
  display_compare(dealer_total, player_total, dealer_cards, player_cards)
  keeping_score(who_wins(dealer_total, player_total), scores)
  display_score(scores)
end

def display_score(scores)
  sleep 3
  clear_screen
  prompt format(messages('display_score'), score1: scores.values[0].to_s,
                                           score2: scores.values[1].to_s,
                                           ties: scores.values[2].to_s)
end

def someone_wins_match?(scores)
  scores[:player_score] == WINNING_SCORE ||
    scores[:dealer_score] == WINNING_SCORE
end

def display_match_winner(scores)
  if scores[:player_score] >= WINNING_SCORE
    prompt(messages('player_wins_match'))
  elsif scores[:dealer_score] >= WINNING_SCORE
    prompt(messages('dealer_wins_match'))
  end
end

def clear_scoreboard(scores)
  scores[:player_score] = 0
  scores[:dealer_score] = 0
  scores[:ties] = 0
end

def prompt_play_again
  puts messages('bar2')
  prompt(messages('play_again?'))
  answer = gets.chomp
  answer.downcase.start_with?('y')
end

def display_goodbye
  clear_screen
  prompt(messages('goodbye'))
end

# main game code

display_greeting
display_rules
clear_screen
scores = { player_score: 0, dealer_score: 0, ties: 0 }

loop do
  deck = initialize_deck
  player_cards = []
  dealer_cards = []

  if someone_wins_match?(scores)
    display_match_winner(scores)
    break unless prompt_play_again
    clear_scoreboard(scores)
    clear_screen
  end

  initial_deal(player_cards, dealer_cards, deck)
  player_total = current_total(player_cards)
  dealer_total = current_total(dealer_cards)
  player_total = player_turn_loop(player_cards, deck, player_total)

  if busted?(player_total)
    player_busts(dealer_total, player_total, dealer_cards, player_cards, scores)
    next
  else
    prompt format(messages('player_stayed'), score: player_total)
  end

  prompt(messages('dealer_turn'))

  dealer_total = dealer_turn_loop(dealer_cards, deck, dealer_total)

  if busted?(dealer_total)
    dealer_busts(dealer_total, player_total, dealer_cards, player_cards, scores)
    next
  else
    prompt format(messages('dealer_stayed'), score: dealer_total)
  end

  nobody_busts(dealer_total, player_total, dealer_cards, player_cards, scores)
end

display_goodbye
