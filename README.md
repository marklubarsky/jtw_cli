# JWT CLI
## Usage
` ./bin/jwt_cli`

###### NOTES

* This tool will require user_key and email before the token can be generated. It will keep asking to continue once those keys entered. 
* JWT generation is implemented using jwt ruby gem. Very simple 'passwordless' usage for simplicity.
* Copying to the clipboard is implemented using `pbcopy`. It's stubbed during testing.