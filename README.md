# Graph Builder

A simple and interactive graph visualization tool built with Flutter. This application allows you to dynamically create and manage a tree-like graph structure.
Main Code is in lib/main.dart

## Features

- **Dynamic Node Creation:** Add new nodes to the graph with a single click.
- **Node Deletion:** Remove nodes and their entire subtrees.
- **Interactive Canvas:** Pan and zoom around the graph to view large structures.
- **Active Node Highlighting:** The currently selected node is highlighted for clarity.
- **Responsive Layout:** The tree layout automatically adjusts as you add or remove nodes.

## Getting Started

### Prerequisites

Make sure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your machine.

### Running the Application

1.  Clone the repository.
2.  Navigate to the project directory:
    ```sh
    cd graph_builder
    ```
3.  Install the dependencies:
    ```sh
    flutter pub get
    ```
4.  Run the application (works best on Chrome):
    ```sh
    flutter run -d chrome
    ```

## How to Use

- **Add a Node:** Select a parent node by clicking on it, then click the **Add Node** button.
- **Delete a Node:** Click the **'x'** icon on a node to delete it and all its children.
- **Navigate:** Click and drag on the canvas to pan. Use your mouse wheel or trackpad to zoom in and out.
