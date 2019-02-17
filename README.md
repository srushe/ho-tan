# Ho-Tan - A Ruby Micropub Endpoint

Ho-Tan is a [Micropub](http://micropub.rocks/) endpoint. It is written in Ruby, as a [Sinatra](http://sinatrarb.com/) application, and supports IndieAuth authorisation, Micropub create, update, delete, and undelete commands, as well as multiple [destinations](https://indieweb.org/destination).

Ho-Tan stores all posts as JSON files, and requires no database to run. It was initially inspired by Barry Frost's [Transformative](https://github.com/barryf/transformative), but informed by my desire to separate the storage of the data from the display on a website. Ho-Tan lets me deal with posts directly in files, while allowing me to change how I process them on the back-end for display.

## Requirements

* Ruby - the latest version (or one version back).

## Installation

Ho-Tan powers my personal website (https://deeden.co.uk/) and, as such, is configured to work for me. How it will work for someone else is an interesting question, and one I'd love to hear more about! For my purposes I run Ho-Tan through [Passenger](https://www.phusionpassenger.com/) on a [Dreamhost VPS](https://www.dreamhost.com/hosting/vps/).

## Configuration

### Environment variables

Use of the application **requires** a number of environment variables to be specified, while others are optional. It does support [dotenv](https://github.com/bkeepers/dotenv) if that floats your boat.

#### Required

| Variable | Format | Purpose |
| -------- | ------ | ------- |
| SYNDICATION_TARGET_CONFIG | Path to a YAML file | Specifies the syndication options the endpoint supports |
| DESTINATION_CONFIG | Path to a YAML file | Specifies the destinations the endpoint supports |
| TOKEN_ENDPOINT | URL | The token endpoint used to verify any IndieAuth token |
| DOMAIN | URL | The domain any IndieAuth token will be verified to be valid for |

##### Syndication targets

The Micropub specification includes the concept of [syndication targets](https://www.w3.org/TR/micropub/#h-syndication-targets), a way of specifying other sites to which posts could be syndicated. Ho-Tan supports this by allowing you to specify `SYNDICATION_TARGET_CONFIG` which should point to a file containing YAML detailing the syndication targets supported by the endpoint. Ho-Tan simply reads the details from the YAML file (if provided) and uses them for any syndication target responses, meaning that it can support extra fields (such as `service` and `user`) that may be added to the specification.

A simple example syndication targets file could look something like:

```yaml
syndication_targets:
  -
    uid: https://twitter.com/
    name: Twitter
  -
    uid: https://facebook.com/
    name: Facebook
```

##### Destinations

Although not mentioned in the Micropub specification there is an experimental concept of "[multi-site indieweb](https://indieweb.org/multi-site_indieweb)" which allows a single endpoint to support multiple posting destinations. For example I use this to support posting most post types to my main website while posting scrobbles to a separate site. Ho-Tan supports this by allowing destinations to be configured in the destinations YAML file (specified by `DESTINATION_CONFIG`).

At least 1 destination **must** be configured (presumably your website), but you can add as many as are required. The first site mentioned will be regarded as the "default" destination (and used when no `mp-destination` is provided in a request), however a different destination can be marked as the default be setting `default: true` on the entry in the file.

Each entry within the destinations YAML file **must** contain values for `uid` (a unique identifier for the destination, which will be used in requests), `name` (which will be sent to clients and displayed in their interfaces), `directory` (a directory path indicating where data files for this destination should be written to and read from), and `base_url` (the start of the url for the destination, used to identify the correct destination when we receive a URL in a request). Only the `uid` and `name` will be used directly in requests, the other fields are purely for internal use.

A simple example destination file could look something like:

```yaml
destinations:
  -
    uid: something_else
    name: Some other site
    directory: content/something_else
    base_url: https://something-else.deeden.co.uk/
  -
    uid: deeden
    name: Me
    directory: content/deeden
    base_url: https://deeden.co.uk/
    default: true
```

##### Token Verification environment variables

Ho-Tan uses the [IndieAuth::TokenVerification](https://github.com/srushe/indieauth-token-verification/) ruby gem to verify an IndieAuth access token against a token endpoint, and the `TOKEN_ENDPOINT` and `DOMAIN` environment variables are required by that gem.

`TOKEN_ENDPOINT` specifies the token endpoint to be used to validate the access token. Failure to specify `TOKEN_ENDPOINT` will result in a `IndieAuth::TokenVerification::MissingTokenEndpointError` error being raised.

`DOMAIN` specifies the domain we expect to see in the response from the validated token. It should match that specified when the token was first generated (presumably your website URL). Failure to specify `DOMAIN` will result in a `IndieAuth::TokenVerification::MissingDomainError` error being raised.

#### Optional

| Variable | Format | Purpose |
| -------- | ------ | ------- |
| MEDIA_ENDPOINT | URL | The URL of the media endpoint for the site, if one exists |
| APP_ENV | String | Specifies the environment the application should run as |

Ho-Tan **does not** support media uploads directly, but instead expects you to have a separate media endpoint (if you so desire). Specifying the URL for that media endpoint (as `MEDIA_ENDPOINT`) will simply result in that URL being included when a [configuration query](https://www.w3.org/TR/micropub/#configuration) is made to the endpoint. If you don't have a media endpoint don't set the variable and the application will still work.

Finally, you can also use `APP_ENV` to tell Sinatra which environment it should be running. For example I use `production` for my live endpoint. You may, or may not, need it. Try it and find out.

## Supported Post Types

Ho-Tan supports all of the standard post types identified by the [Indieweb::PostTypes](https://github.com/srushe/indieweb-post_types) ruby gem, specifically `rsvp`, `reply`, `repost`, `like`, `video`, `photo`, `article`, and `note`. It also supports some non-standard types, specifically `bookmark`, `read`, and `scrobble` (as I wanted them).

## Contributing

While Ho-Tan is written with a view to "[self-dogfooding](https://indieweb.org/selfdogfood)" I'm still happy for other people to use and contribute to the project. Bug reports and pull requests are welcome on GitHub at https://github.com/srushe/ho-tan. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

This application is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Ho-Tan?

![Ho-Tan in the Elders chamber](static/ho-tan.jpeg)

Ho-Tan is one of the Elders of [Yonderland](https://en.wikipedia.org/wiki/Yonderland), and serves as the scribe/record keeper. He was played, in the TV series, by [Laurence Rickard](https://twitter.com/Lazbotron). I love Yonderland.
