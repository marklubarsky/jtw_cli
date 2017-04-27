require 'spec_helper'
describe JwtCli do
  let(:cli) { JwtCli.new }

  def test_start_input(expected_first_prompts:)
    allow(STDOUT).to receive(:puts)
    cli.start
    expected_first_prompts.each do |prompt|
      expect(STDOUT).to have_received(:puts).with(prompt)
    end
  end

  def test_key_input(key, expected_next_prompt:)
    allow(STDOUT).to receive(:puts)
    expect(STDIN).to receive(:gets).and_return(key)
    cli.input
    expect(STDOUT).to have_received(:puts).with(expected_next_prompt)
  end

  def test_value_input(value, expected_next_prompt:)
    allow(STDOUT).to receive(:puts)
    expect(STDIN).to receive(:gets).and_return(value)
    cli.input
    expect(STDOUT).to have_received(:puts).with(expected_next_prompt).at_least(:once)
  end

  def test_key_value_input(key:, value:, expected_value_prompt:, expected_next_key_prompt:)
    test_key_input(key, expected_next_prompt: expected_value_prompt)
    test_value_input(value, expected_next_prompt: expected_next_key_prompt)
  end

  def test_continue(answer, expected_next_prompt:, expect_to_continue:)
    allow(STDOUT).to receive(:puts).with(expected_next_prompt)
    expect(STDIN).to receive(:gets).and_return(answer)

    expect(cli.input).to be expect_to_continue
    expect(STDOUT).to have_received(:puts).with(expected_next_prompt).at_least(:once)
  end

  def setup_test_with_required_input(user_key:, email:)
    test_start_input(expected_first_prompts: ['Enter key 1'])
    test_key_value_input(key: 'user_key',
      value: user_key,
      expected_value_prompt: 'Enter user_key',
      expected_next_key_prompt: 'Enter key 2')
    test_key_value_input(key: 'email',
      value: email,
      expected_value_prompt: 'Enter email',
      expected_next_key_prompt: 'Continue? (y/n)'
    )
  end

  def setup_test_without_required_input(user_key:)
    test_start_input(expected_first_prompts: ['Starting with JWT token generation', 'Enter key 1'])
    test_key_value_input(key: 'user_key',
                         value: user_key,
                         expected_value_prompt: 'Enter user_key',
                         expected_next_key_prompt: 'Enter key 2')
  end

  def setup_test_copy_jwt_to_clipboard
    expected_token = 'foobartoken'
    allow(JWT).to receive(:encode).and_return(expected_token)
    allow(cli).to receive(:copy_to_clipboard).with(expected_token)
    expected_token
  end

  def test_copy_jwt_to_clipboard(expected_payload:, expected_token:)
    expect(JWT).to have_received(:encode).with(expected_payload, nil, 'none', { :typ => "JWT" })
    expect(cli).to have_received(:copy_to_clipboard).with(expected_token)
  end

  describe '#run' do
    it 'runs #start and then #input in a loop until it returns false' do
      expect(cli).to receive(:start)
      expect(cli).to receive(:input).and_return(true)
      expect(cli).to receive(:input).and_return(true)
      expect(cli).to receive(:input).and_return(false)
      expect(cli).to_not receive(:input)
      cli.run
    end
  end

  describe "#start" do
    it 'should provide a proper prompt' do
      test_start_input(expected_first_prompts: ['Starting with JWT token generation', 'Enter key 1'])
    end
  end

  describe '#input' do
    context 'validations' do
      context 'when email entered in the wrong format' do
        it 'should show error and ask again' do
          setup_test_without_required_input(user_key: 'foo')

          test_key_value_input(
            key: 'email',
            value: 'emailwithwrongformat',
            expected_value_prompt: 'Enter email',
            expected_next_key_prompt: 'Invalid format for email. Try again.'
          )
        end
      end
    end
    context 'accepts multiple input' do
      context 'when user_key and email have not been entered yet' do
        it 'keeps prompting for next keys with an incrementing counter' do
          setup_test_without_required_input(user_key: 'foo')

          test_key_value_input(key: 'some_key',
            value: 'some_value',
            expected_value_prompt: 'Enter some_key',
            expected_next_key_prompt: 'Enter key 3'
          )

          test_key_value_input(
            key: 'some_other_key',
            value: 'some_other_value',
            expected_value_prompt: 'Enter some_other_key',
            expected_next_key_prompt: 'Enter key 4'
          )

        end
        context 'when valid user_key and email already entered' do
          context 'when asking to continue' do
            context 'when answer is y' do
              it 'continues forever' do
                setup_test_with_required_input(user_key: 'foo', email: 'foo@bar.com')

                test_continue('y', expected_next_prompt: 'Enter key 3', expect_to_continue: true)

                test_key_value_input(key: 'some_key',
                  value: 'some_value',
                  expected_value_prompt: 'Enter some_key',
                  expected_next_key_prompt: 'Continue? (y/n)'
                )

                test_continue('y', expected_next_prompt: 'Enter key 4', expect_to_continue: true)

                test_key_value_input(key: 'some_other_key',
                  value: 'some_other_value',
                  expected_value_prompt: 'Enter some_key',
                  expected_next_key_prompt: 'Continue? (y/n)'
                )
              end
            end

            context 'when answer is n' do
              it 'copies to clipboard and returns false' do
                expected_token = setup_test_copy_jwt_to_clipboard

                setup_test_with_required_input(user_key: 'foo', email: 'foo@bar.com')

                test_continue('n', expected_next_prompt: 'The JWT has been copied to your clipboard!', expect_to_continue: false)
                test_copy_jwt_to_clipboard(
                  expected_payload: { "user_key"=>"foo", "email"=>"foo@bar.com" },
                  expected_token: expected_token
                )
              end
            end

            context 'when answer is neither y or n' do
              it 'keeps asking to continue again until y/n chosen' do
                setup_test_with_required_input(user_key: 'foo', email: 'foo@bar.com')

                test_continue('dontknow', expected_next_prompt: 'Try again. Continue? (y/n)', expect_to_continue: true)
                test_continue('stilldontknow', expected_next_prompt: 'Try again. Continue? (y/n)', expect_to_continue: true)
                test_continue('y', expected_next_prompt: 'Enter key 3', expect_to_continue: true)
              end
            end
          end
        end
      end
    end
  end
end


