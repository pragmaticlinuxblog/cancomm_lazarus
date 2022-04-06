# TCanSocket component for Lazarus
[![License: FPC modified LGPL](https://img.shields.io/badge/license-FPC%20modified%20LGPL-blue.svg)](https://wiki.lazarus.freepascal.org/FPC_modified_LGPL)

![](docs/images/TCanSocket.png) `TCanSocket` is a Lazarus component for convenient and easy-to-use access to CAN communication. Perfect for when your Lazarus application should participate or monitor the communication on a Controller Area Network. Under the hood, it uses the SocketCAN functionality of the Linux kernel.

![](docs/images/tcansocket_showcase_lazarus_ide.png)

Supported functionality:

* List all SocketCAN devices known to your Linux system.
* Transmit and receive CAN messages.
* Event handlers for:
  * Reception of CAN messages and error frames.
  * Transmit completed of a CAN message.
  * Connect and disconnect events.

## Getting started

To get started with the `TCanSocket` component, it is recommended to download the latest stable release from the [releases](https://github.com/pragmaticlinuxblog/cancomm_lazarus/releases) page. Next, read through the getting started documentation in the [user manual](https://pragmaticlinuxblog.github.io/cancomm_lazarus/).

## User manual

The online user manual is located at the following location:

- [https://pragmaticlinuxblog.github.io/cancomm_lazarus/](https://pragmaticlinuxblog.github.io/cancomm_lazarus/)

## Development

Development of the `TCanSocket`component takes place at GitHub. Feel free to contribute by submitting issues and pull requests.

* [https://github.com/pragmaticlinuxblog/cancomm_lazarus](https://github.com/pragmaticlinuxblog/cancomm_lazarus)
