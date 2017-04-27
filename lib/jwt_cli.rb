require 'jwt'
class JwtCli
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

  def run
    start
    loop until !input
  end

  def start
    puts "Starting with JWT token generation"
    puts 'Enter key 1'
    reset_payload
    reset_context
  end

  def input
    if expecting_key?
      if asked_to_continue?
        return process_continue
      else
        process_key
      end
    else
      process_value
    end

    true
  end

  private

  def add_input(key:, value:)
    @payload[key] = value
  end

  def asked_to_continue?
    !!@asked_to_continue
  end

  def continue
    @asked_to_continue = false
  end

  def copy_to_clipboard(str)
    IO.popen('pbcopy', 'w') { |f| f << str }
  end

  def current_key
    @current_key
  end

  def current_value
    @current_value
  end

  def expecting_key?
    current_key.nil?
  end

  def expecting_answer_to_continue?
    !!@asked_to_continue
  end

  def generate_jwt
    #simplistic implementation with nil password
    JWT.encode @payload, nil, 'none', { :typ => "JWT" }
  end

  def payload
    @payload
  end

  def process_continue
    cont = STDIN.gets.chomp
    if cont == 'y'
      puts "Enter key #{@payload.keys.count + 1}"
      continue
      return true
    elsif cont == 'n'
      copy_to_clipboard(generate_jwt)
      puts 'The JWT has been copied to your clipboard!'
      return false
    else #ask again
      puts "Try again. Continue? (y/n)"
      return true
    end
  end

  def process_key
    @current_key = STDIN.gets.chomp
    puts "Enter #{@current_key}"
  end

  def process_value
    value = STDIN.gets.chomp

    if validate_input(key: current_key, value: value)
      add_input(key: current_key, value: value)

      if required_entered? && !asked_to_continue?
        @asked_to_continue = true
        puts "Continue? (y/n)"
      else
        puts "Enter key #{payload.keys.count + 1}"
      end

      reset_context

    else
      puts "Invalid format for #{@current_key}. Try again."
    end
  end

  def required_entered?
    !payload['user_key'].nil? && !payload['email'].nil?
  end

  def reset_context
    @current_key, @current_value = nil, nil
  end

  def reset_payload
    @payload = {}
  end

  def validate_input(key:, value:)
    if key == 'email'
      value =~ VALID_EMAIL_REGEX
    else
      true
    end
  end
end
