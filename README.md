<p align="center">
  <img width="250" height="219" src="https://user-images.githubusercontent.com/73386/71603660-25697100-2b1b-11ea-8b04-dad3b0b7bae5.png">
</p>

# Recognizer

Recognizer is a standalone service designed to provide the functionality of both a centralization authentication service
and the user account service.

### Rationale

At System76 we have multiple applications that use the same underlying data but through differing authentication flows.
In order to decouple our applications from authentication, improve maintainability, and faster feature iteration we have
decided to build a standalone service to replace existing auth flows within our platform.

**_While the best attempts are made to ensure the software herein is suitable for use by others, it is being developed
for use with existing projects at System76. For this reason, modification to the software may be necessary for use
elsewhere._**

## Running

For convenience a `docker-compose.yml` file has been included to manage the MySQL and Redis instances. Before we run
our test suite, or start local development, we need to stand up our instances:

```shell
$ docker-compose up
```

Now we're ready to run our tests:

```shell
$ mix test
Finished in 0.2 seconds
28 tests, 0 failures
```

Or run our local development server:

```shell
$ mix ecto.setup
$ mix phx.server
```

## Releases

This repository includes a continuous integration and deployment. Simply make a PR to the `master` branch, and once it's
merged, it will be deployed to production.

## License

The Recognizer source code is released under GPL3 by [@System76](https://github.com/system76).

See [LICENSE](https://github.com/doomspork/recognizer/blob/master/LICENSE) for more information.
