<h1 align="center">
  Level10
</h1>

<h4 align="center">
  A real-time multiplayer card game written with
  <a href="https://github.com/phoenixframework/phoenix_live_view">Phoenix LiveView</a>
  <br><br>
  <img src="https://user-images.githubusercontent.com/3421625/90838024-eccc1100-e310-11ea-8685-59ae938b9bae.gif" alt="Animated gif of Level 10 in action">
</h4>

## Development

After cloning the repo:

- Install dependencies with `mix deps.get`
- Install Node.js dependencies with `(cd assets && yarn)`
- Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

### Simulate clustering

Level 10 takes advantage of Erlang clustering for scale and uptime purposes.
While in development mode, the application uses Libcluster's Gossip strategy if
a node name is provided when starting the application.

Thus, clustering can be simulated by starting up the application as follows:

```sh
# In one terminal window
PORT=4000 iex --cookie level10 --name 4000 -S mix phx.server

# In a different terminal window
PORT=4001 iex --cookie level10 --name 4001 -S mix phx.server
```

## Production

You can build a docker image that can run anywhere docker images can with `docker build .`

The official version of Level 10 runs in [Digital Ocean
Kubernetes](https://m.do.co/c/757db256ded5). You can do the same by tweaking a
few files in [the deployment manifest](k8s/deployment.yaml) and running `kubectl apply -f k8s`

## Contributing

Information about contributing can be found in [CONTRIBUTING.md](CONTRIBUTING.md)
