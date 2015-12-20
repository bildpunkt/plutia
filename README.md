# plutia

_a maidbot prototype_, currently powering [@pluutia](https://twitter.com/pluutia) on Twitter.

## What does a maidbot do?

A maidbot is, to keep it short, just a simple bot acting like a maid, wishing you good morning/evening, cheering you up and offering you several things.

My personal goal of plutia was to create a bot that is as close as possible to human-like behaviour with replies to stuff that other people on Twitter would also do. So it's part a learning experience/social experiment.

## Installation

### Requirements

* A place where plutia can be run for a long time.
* Ruby (install a `ruby` package or use RubyInstaller)
* A [Twitter Application](https://apps.twitter.com/) to be bound to.

### Configuration

Simply copy the `config.example.yml` and rename it to `config.yml` and fill out the empty fields!

### Starting

Just run `ruby plutia.rb` and you are good to go!

## Additional Configuration

plutia already comes with a set of several triggers and replies which she can work with, but of course, anyone can extend these lists and add more to them.

### Triggers

A trigger is something plutia needs to see in the incoming tweets (either from a tweet in the User Stream or a reply) to act upon, you can find them in `config.yml`

**Example:**
```yml
- :key: :hug
  :require_mention: true
  :triggers:
    - /give me a hug/
    - /hug please/
```

* `:key`: The list name of the file inside `replies/`
* `:require_mention`: Does this trigger need to be in a mention or not?
* `:triggers`: Supply one or multiple triggers for that list of replies (you can use regex here)

### Replies

Replies are the things plutia is saying to you after she gets triggered with one of the specified keywords. You can find these in `replies/`. These are simple files just including a list of strings she will pull out one off randomly, so for more variety, specify more!

## Contributing

If you have any ideas for more replies and things plutia could reply to, either [open an issue](https://github.com/pixeldesu/plutia/issues/new) with your suggestions or [fork](https://github.com/pixeldesu/plutia/fork) the repository and make your changes with the guide above and submit them with a Pull Request!

## Contributors

* [nilsding](https://github.com/nilsding) who helped cleaning up huge parts of the code!

## License

plutia is licensed under the aGPLv3 license

