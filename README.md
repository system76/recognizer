<p align="center">
  <img width="250" height="219" src="https://user-images.githubusercontent.com/73386/71603660-25697100-2b1b-11ea-8b04-dad3b0b7bae5.png">
</p>

# Recognizer

Recognizer is a standalone service designed to provide the functionality of both a centralization authentication service and the user account service.

### Rationale

At System76 we have multiple applications that use the same underlying data but through differing authentication flows. In order to decouple our applications from authentication, improve maintainability, and faster feature iteration we have decided to build a standalone service to replace existing auth flows within our platform. In future releases we expect to extend our authentication functionality to include developing an OAuth2.0 provider for System76 accounts.

**_While the best attempts are made to ensure the software herein is suitable for use by others, it is being developed for use with existing projects at System76. For this reason, modification to the software may be necessary for use elsewhere._**

## Tests

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

## Releases

While the final build artifact is a Docker image we do use `mix release` to build a release binary for use within the final image. The process of creating new releases has been simplified by the included Makefile.

In order to take advantage of our Makefile we need to install Docker, the AWS CLI client, and ensure our AWS credentials are accessible at `AWS_ACCESS_KEY_ID` and  `AWS_SECRET_ACCESS_KEY`. Once our build environment has been setup we're ready to build and push new releases with the appropriately named make commands:

```shell
make build # Build a new image
make push # Push the image to AWS ECR
```

## License

The Recognizer source code is released under a Apache 2.0 License by [@System76](https://github.com/system76).

See [LICENSE](https://github.com/doomspork/recognizer/blob/master/LICENSE) for more information.
