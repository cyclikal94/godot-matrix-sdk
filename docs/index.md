---
layout: page
title: Godot Matrix SDK
---

⚠️ I've not touched in a while and it's not in a usable state ... you probably shouldn't bother with it fyi!

A Matrix SDK for Godot written in GDScript.

Please note, this is a work in progress and is primarily for my learning purposes.

## Features

- [x] [Matrix Client-Server API v1.12](https://spec.matrix.org/v1.12/client-server-api/)
    - Following not yet adapted:
        - [Matrix Client-Server (Authenticated) Content Repository API](https://github.com/matrix-org/matrix-spec/blob/main/data/api/client-server/authed-content-repo.yaml)
        - [Matrix Client-Server Content Repository API](https://github.com/matrix-org/matrix-spec/blob/main/data/api/client-server/content-repo.yaml)
        - [Matrix Client-Server Relations API](https://github.com/matrix-org/matrix-spec/blob/main/data/api/client-server/relations.yaml)

## To-Do

Lots of things, but noting some below:
- [ ] Create a Login flow (using a directly provided `access_token` for now)
    - [ ] Validate provided homeserver URL
        - [ ] Get delegated homeserver URL from `.well-known` files, if applicable.
    - [ ] Validate `access_token` against homeserver (/ delegated homeserver)
        - [ ] Create function to construct `headers` PackedStringArray for you following validation of `access_token`
    - [ ] Auto-populate MatrixClientServer variables after successful "Login"
- [ ] Document structure of MatrixClientServerResponse
    - [ ] Provide sample code snippets for using functions returning this
        - [ ] Checking for errors (and displaying error message)
        - [ ] Checking for success
        - [ ] Accessing the resposne
    - [ ] Probably provide helper functions within MatrixClientServerReponse to do this for you?
- [ ] Figure out why the 3 OpenAPI YAMLs for `Authenicated Content Repository`, `Content Repository` and `Relations` API don't have `Schema` definitions and re-produce them as functions (like the rest)

## Installation
1. Open Godot, click `AssetLib` from the top, then `Import...`.
2. Browse and select the downloaded ZIP file.
3. Accept default import settings.
4. Open Project Settings, Plugins, Enable `Godot Matrix SDK`

### How to use
1. Add a MatrixClientServer node to your scene
2. Reference the node from your desired script i.e. `@onready var matrix_client_server: MatrixClientServer = $MatrixClientServer`
3. Provide `access_token`, `homeserver` and `headers` for functions requiring a Matrix Account (this will be fixed / made better in a future update)