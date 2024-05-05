# frozen_string_literal: true

require 'pry'
require 'yaml'

MESSAGES = YAML.load_file('ttt_messages.yml')

WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] +
                [[1, 4, 7], [2, 5, 8], [3, 6, 9]] +
                [[1, 5, 9], [3, 5, 7]]
INITIAL_MARKER = ' '
PLAYER_MARKER = 'X'
COMPUTER_MARKER = 'O'
ROUNDS = 5

def messages(message)
  MESSAGES[message]
end

def prompt(msg)
  puts "=> #{msg}"
end

def clear_screen
  (system 'clear') || (system 'cls')
end

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize

def display_board(brd)
  clear_screen
  prompt(messages('player_markers'))
  puts ''
  puts '     |     |'
  puts "  #{brd[1]}  |  #{brd[2]}  |  #{brd[3]}"
  puts '     |     |'
  puts '-----+-----+-----'
  puts '     |     |'
  puts "  #{brd[4]}  |  #{brd[5]}  |  #{brd[6]}"
  puts '     |     |           1 | 2 | 3'
  puts '-----+-----+-----     ---+---+---'
  puts '     |     |           4 | 5 | 6'
  puts "  #{brd[7]}  |  #{brd[8]}  |  #{brd[9]}       ---+---+---"
  puts '     |     |           7 | 8 | 9'
  puts ''
end

# rubocop:enable Metrics/MethodLength, Metrics/AbcSize

def initialize_board
  new_board = {}
  (1..9).each { |num| new_board[num] = INITIAL_MARKER }
  p new_board
end

def empty_squares(brd)
  brd.keys.select { |num| brd[num] == INITIAL_MARKER }
end

def joiner(arr, delimiter = ', ', word = 'or')
  case arr.size
  when 0 then ''
  when 1 then arr.first.to_s
  when 2 then arr.join(" #{word} ")
  else
    arr[-1] = "#{word} #{arr.last}"
    arr.join(delimiter)
  end
end

def alternate_player(current_player)
  current_player == 'Player' ? 'Computer' : 'Player'
end

def player_places_piece!(brd)
  square = ''
  loop do
    prompt format(messages('choose_position'), square: joiner(empty_squares(brd)))
    square = gets.chomp.to_i
    break if empty_squares(brd).include?(square)

    prompt(messages('valid_choice'))
  end
  brd[square] = PLAYER_MARKER
end

def defense_offense(square, brd, marker)
  WINNING_LINES.each do |line|
    square = find_at_risk_square(line, brd, marker)
    return square unless square.nil?
  end
  nil
end

def computer_places_piece!(brd)
  square = nil

  square = defense_offense(square, brd, COMPUTER_MARKER)

  square ||= defense_offense(square, brd, PLAYER_MARKER)

  square = 5 if !square && brd[5] == INITIAL_MARKER

  square ||= empty_squares(brd).sample

  brd[square] = COMPUTER_MARKER
end

def place_piece!(brd, current_player)
  if current_player == 'Player'
    player_places_piece!(brd)
  else
    computer_places_piece!(brd)
  end
end

def at_risk(line, board, marker)
  board.values_at(*line).count(marker) == 2
end

def risk_guard(line, board)
  board.select { |k, v| line.include?(k) && v == INITIAL_MARKER }.keys.first
end

def find_at_risk_square(line, board, marker)
  risk_guard(line, board) if at_risk(line, board, marker)
end

def board_full?(brd)
  empty_squares(brd).empty?
end

def someone_won?(brd)
  !!detect_winner(brd)
end

def detect_winner(brd)
  WINNING_LINES.each do |line|
    if brd.values_at(*line).count(PLAYER_MARKER) == 3
      return 'Player'
    elsif brd.values_at(*line).count(COMPUTER_MARKER) == 3
      return 'Computer'
    end
  end
  nil
end

def keeping_score(winner, score)
  case winner
  when 'Player'
    score['Player'] += 1
  when 'Computer'
    score['Computer'] += 1
  else
    score['Ties'] += 1
  end
end

def display_score(score_hash)
  prompt format(messages('current_score'), player_score: score_hash['Player'],
                                           computer_score: score_hash['Computer'],
                                           ties: score_hash['Ties'])
  sleep 2
end

def display_winner(brd)
  if someone_won?(brd)
    prompt format(messages('winner'), winner: detect_winner(brd))
  else
    prompt(messages('tie'))
  end
end

def player_choose
  loop do
    prompt(messages('player_choose'))
    choice = gets.chomp.downcase
    if choice == 'p'
      return 'Player'
    elsif choice == 'c'
      return 'Computer'
    end

    prompt(messages('valid_choice'))
  end
end

def who_chooses
  loop do
    prompt(messages('who_first'))
    answer = gets.chomp.downcase
    return answer if %w[p c d].include?(answer)

    prompt(messages('valid_choice'))
  end
end

def starting_player
  answer = who_chooses

  case answer
  when 'd' then player = %w[Player Computer].sample
  when 'c' then player = 'Computer'
  when 'p' then player = player_choose
  end
  player
end

def each_round(current_player, score_hash)
  board = initialize_board
  loop do
    display_board(board)
    place_piece!(board, current_player)
    current_player = alternate_player(current_player)
    display_board(board)
    break if someone_won?(board) || board_full?(board)
  end

  display_winner(board)
  keeping_score(detect_winner(board), score_hash)
end

def ask_name
  loop do
    prompt(messages('welcome'))
    name = gets.chomp.strip.capitalize

    return name unless name.strip.empty?

    prompt(messages('valid_name'))
  end
  name
end

def greeting
  name = ask_name
  prompt format(messages('greeting_name'), name: name)
end

def need_rules?
  prompt(messages('need_rules'))
  answer = gets.chomp.downcase
  clear_screen
  rules_info if answer.start_with?('y')
end

def rules_info
  loop do
    prompt(messages('rules'))
    prompt(messages('type_to_exit'))

    answer = gets.chomp.downcase
    break if answer.include?('y')
  end
end

def play_again?
  prompt(messages('play_again?'))
  answer = gets.chomp.downcase
  answer.start_with?('y')
end

# Main Game Code:

greeting
need_rules?
clear_screen
score = { 'Player' => 0, 'Computer' => 0, 'Ties' => 0 }
current_player = starting_player

loop do
  each_round(current_player, score)
  display_score(score)

  if score['Player'] == ROUNDS
    prompt(messages('player_wins'))
    break unless play_again?

  elsif score['Computer'] == ROUNDS
    prompt(messages('computer_wins'))
    break unless play_again?

    clear_screen
    current_player = starting_player
    score = { 'Player' => 0, 'Computer' => 0, 'Ties' => 0 }
  end
end

prompt(messages('goodbye'))
