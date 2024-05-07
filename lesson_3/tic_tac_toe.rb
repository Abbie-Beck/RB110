require 'yaml'

MESSAGES = YAML.load_file('ttt_messages.yml')

WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] +
                [[1, 4, 7], [2, 5, 8], [3, 6, 9]] +
                [[1, 5, 9], [3, 5, 7]]
INITIAL_MARKER = ' '
PLAYER_MARKER = 'X'
COMPUTER_MARKER = 'O'
WINNING_SCORE = 5

def messages(message)
  MESSAGES[message]
end

def prompt(msg)
  puts "=> #{msg}"
end

def clear_screen
  (system 'clear') || (system 'cls')
end

# rubocop:disable Metrics/AbcSize

def display_board(board)
  clear_screen
  prompt(messages('player_markers'))
  puts ' '
  puts '     |     |'
  puts "  #{board[1]}  |  #{board[2]}  |  #{board[3]}"
  puts '     |     |'
  puts '-----+-----+-----'
  puts '     |     |'
  puts "  #{board[4]}  |  #{board[5]}  |  #{board[6]}"
  puts '     |     |           1 | 2 | 3'
  puts '-----+-----+-----     ---+---+---'
  puts '     |     |           4 | 5 | 6'
  puts "  #{board[7]}  |  #{board[8]}  |  #{board[9]}       ---+---+---"
  puts '     |     |           7 | 8 | 9'
  puts ''
end

# rubocop:enable Metrics/AbcSize

def initialize_board
  new_board = {}
  (1..9).each { |num| new_board[num] = INITIAL_MARKER }
  p new_board
end

def empty_squares(board)
  board.keys.select { |num| board[num] == INITIAL_MARKER }
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

# rubocop:disable Metrics/AbcSize

def player_places_piece!(board, scores)
  square = ''
  loop do
    prompt format(messages('current_score'), player_score: scores['Player'],
                                             computer_score: scores['Computer'],
                                             ties: scores['Ties'])
    prompt format(messages('choose_box'), square: joiner(empty_squares(board)))
    square = gets.chomp.to_i
    break if empty_squares(board).include?(square)

    prompt(messages('valid_choice'))
  end
  board[square] = PLAYER_MARKER
end

# rubocop:enable Metrics/AbcSize

def defense_offense(square, board, marker)
  WINNING_LINES.each do |line|
    square = find_at_risk_square(line, board, marker)
    return square unless square.nil?
  end
  nil
end

def computer_places_piece!(board)
  square = nil

  square = defense_offense(square, board, COMPUTER_MARKER)

  square ||= defense_offense(square, board, PLAYER_MARKER)

  square = 5 if !square && board[5] == INITIAL_MARKER

  square ||= empty_squares(board).sample

  board[square] = COMPUTER_MARKER
end

def place_piece!(board, current_player, scores)
  if current_player == 'Player'
    player_places_piece!(board, scores)
  else
    computer_places_piece!(board)
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

def board_full?(board)
  empty_squares(board).empty?
end

def someone_won?(board)
  !!detect_winner(board)
end

def detect_winner(board)
  WINNING_LINES.each do |line|
    if board.values_at(*line).count(PLAYER_MARKER) == 3
      return 'Player'
    elsif board.values_at(*line).count(COMPUTER_MARKER) == 3
      return 'Computer'
    end
  end
  nil
end

def keeping_score(winner, scores)
  case winner
  when 'Player'
    scores['Player'] += 1
  when 'Computer'
    scores['Computer'] += 1
  else
    scores['Ties'] += 1
  end
end

def display_score(scores)
  prompt format(messages('current_score'), player_score: scores['Player'],
                                           computer_score: scores['Computer'],
                                           ties: scores['Ties'])
  sleep 2
end

def display_winner(board)
  if someone_won?(board)
    prompt format(messages('winner'), winner: detect_winner(board))
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

def prompt_who_chooses
  loop do
    prompt(messages('who_first'))
    answer = gets.chomp.downcase
    return answer if %w(p c d).include?(answer)

    prompt(messages('valid_choice'))
  end
end

def starting_player
  answer = prompt_who_chooses

  case answer
  when 'd' then player = %w(Player Computer).sample
  when 'c' then player = 'Computer'
  when 'p' then player = player_choose
  end
  player
end

def game_round_loop(current_player, scores)
  board = initialize_board
  loop do
    display_board(board)
    place_piece!(board, current_player, scores)
    current_player = alternate_player(current_player)
    display_board(board)
    break if someone_won?(board) || board_full?(board)
  end

  display_winner(board)
  keeping_score(detect_winner(board), scores)
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

def prompt_play_again?
  prompt(messages('play_again?'))
  answer = gets.chomp.downcase
  answer.start_with?('y')
end

# Main Game Code:

display_greeting
display_rules
clear_screen
scores = { 'Player' => 0, 'Computer' => 0, 'Ties' => 0 }
current_player = starting_player

loop do
  game_round_loop(current_player, scores)
  display_score(scores)

  if scores['Player'] == WINNING_SCORE
    prompt(messages('player_wins'))
    break unless prompt_play_again?

  elsif scores['Computer'] == WINNING_SCORE
    prompt(messages('computer_wins'))
    break unless prompt_play_again?

    clear_screen
    current_player = starting_player
    scores = { 'Player' => 0, 'Computer' => 0, 'Ties' => 0 }
  end
end

prompt(messages('goodbye'))
