require 'open-uri'
require 'json'

class GamesController < ApplicationController
  def new
    @letters = generate_grid(10)
    session[:total_score] ||= 0
  end

  def score
    @attempt = params[:word]
    @grid = params[:letters]
    @start_time = Time.parse(params[:start_time])
    @end_time = Time.now
    @result = run_game(@attempt, @grid, @start_time, @end_time)

    update_total_score(@result[:score])
  end

  private

  def generate_grid(grid_size)
    Array.new(grid_size) { ('A'..'Z').to_a.sample }
  end

  def included?(guess, grid)
    guess.chars.all? { |letter| guess.count(letter) <= grid.count(letter) }
  end

  def compute_score(attempt, time_taken)
    time_taken > 60.0 ? 0 : (attempt.size * (1.0 - (time_taken / 60.0)))
  end

  def run_game(attempt, grid, start_time, end_time)
    result = { time: end_time - start_time }

    score_and_message = score_and_message(attempt, grid, result[:time])
    result[:score] = score_and_message.first
    result[:message] = score_and_message.last

    result
  end

  def score_and_message(attempt, grid, time)
    grid_array = grid.split(',')
    if included?(attempt.upcase, grid_array)
      if english_word?(attempt)
        score = compute_score(attempt, time)
        return [score, "Congratulations! #{attempt} is a valid English word"]
      else
        return [0, "Sorry but #{attempt} does not seem to be a valid English word"]
      end
    else
      if english_word?(attempt)
        return [0, "Sorry but #{attempt} can't be built out of #{grid}"]
      else
        return [0, "Sorry but #{attempt} does not seem to be a valid English word"]
      end
    end
  end

  def english_word?(word)
    encoded_word = URI.encode_www_form_component(word)
    response = URI.parse("https://wagon-dictionary.herokuapp.com/#{encoded_word}")
    json = JSON.parse(response.read)
    json['found']
  end

  def update_total_score(score)
    session[:total_score] += score
  end
end
