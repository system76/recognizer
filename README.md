<p align="center">
  <img width="250" height="219" src="https://user-images.githubusercontent.com/73386/71603660-25697100-2b1b-11ea-8b04-dad3b0b7bae5.png">
</p>

# Recognizer

Recognizer is a standalone service designed to provide the functionality of both a centralization authentication service and the user account service.

While the best attempts are made to ensure the software herein is suitable for use by others, it is being developed for use with existing projects at System76.

### Running tests

For convince a `docker-compose.yml` file has been included to manage the MySQL instance during testing. Before we run our test suite, we need to stand up our MySQL instance:

```shell
$ docker-compose up
```

Now we're ready to run our tests:

```shell
$ mix test
Finished in 0.2 seconds
28 tests, 0 failures
```

### License

The Recognizer source code is released under a Apache 2.0 License by @system76

See [LICENSE](https://github.com/doomspork/recognizer/blob/master/LICENSE) for more information.
