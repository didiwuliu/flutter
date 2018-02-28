// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'media_query.dart';
import 'primary_scroll_controller.dart';
import 'scroll_controller.dart';
import 'scroll_physics.dart';
import 'scrollable.dart';
import 'sliver.dart';
import 'viewport.dart';

/// A widget that scrolls.
///
/// Scrollable widgets consist of three pieces:
///
///  1. A [Scrollable] widget, which listens for various user gestures and
///     implements the interaction design for scrolling.
///  2. A viewport widget, such as [Viewport] or [ShrinkWrappingViewport], which
///     implements the visual design for scrolling by displaying only a portion
///     of the widgets inside the scroll view.
///  3. One or more slivers, which are widgets that can be composed to created
///     various scrolling effects, such as lists, grids, and expanding headers.
///
/// [ScrollView] helps orchestrate these pieces by creating the [Scrollable] and
/// the viewport and deferring to its subclass to create the slivers.
///
/// To control the initial scroll offset of the scroll view, provide a
/// [controller] with its [ScrollController.initialScrollOffset] property set.
///
/// See also:
///
///  * [ListView], which is a commonly used [ScrollView] that displays a
///    scrolling, linear list of child widgets.
///  * [PageView], which is a scrolling list of child widgets that are each the
///    size of the viewport.
///  * [GridView], which is a [ScrollView] that displays a scrolling, 2D array
///    of child widgets.
///  * [CustomScrollView], which is a [ScrollView] that creates custom scroll
///    effects using slivers.
///  * [ScrollNotification] and [NotificationListener], which can be used to watch
///    the scroll position without using a [ScrollController].
abstract class ScrollView extends StatelessWidget {
  /// Creates a widget that scrolls.
  ///
  /// If the [primary] argument is true, the [controller] must be null.
  ScrollView({
    Key key,
    this.scrollDirection: Axis.vertical,
    this.reverse: false,
    this.controller,
    bool primary,
    ScrollPhysics physics,
    this.shrinkWrap: false,
  }) : assert(reverse != null),
       assert(shrinkWrap != null),
       assert(!(controller != null && primary == true),
           'Primary ScrollViews obtain their ScrollController via inheritance from a PrimaryScrollController widget. '
           'You cannot both set primary to true and pass an explicit controller.'
       ),
       primary = primary ?? controller == null && scrollDirection == Axis.vertical,
       physics = physics ?? (primary == true || (primary == null && controller == null && scrollDirection == Axis.vertical) ? const AlwaysScrollableScrollPhysics() : null),
       super(key: key);

  /// The axis along which the scroll view scrolls.
  ///
  /// Defaults to [Axis.vertical].
  final Axis scrollDirection;

  /// Whether the scroll view scrolls in the reading direction.
  ///
  /// For example, if the reading direction is left-to-right and
  /// [scrollDirection] is [Axis.horizontal], then the scroll view scrolls from
  /// left to right when [reverse] is false and from right to left when
  /// [reverse] is true.
  ///
  /// Similarly, if [scrollDirection] is [Axis.vertical], then the scroll view
  /// scrolls from top to bottom when [reverse] is false and from bottom to top
  /// when [reverse] is true.
  ///
  /// Defaults to false.
  final bool reverse;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  ///
  /// Must be null if [primary] is true.
  ///
  /// A [ScrollController] serves several purposes. It can be used to control
  /// the initial scroll position (see [ScrollController.initialScrollOffset]).
  /// It can be used to control whether the scroll view should automatically
  /// save and restore its scroll position in the [PageStorage] (see
  /// [ScrollController.keepScrollOffset]). It can be used to read the current
  /// scroll position (see [ScrollController.offset]), or change it (see
  /// [ScrollController.animateTo]).
  final ScrollController controller;

  /// Whether this is the primary scroll view associated with the parent
  /// [PrimaryScrollController].
  ///
  /// When this is true, the scroll view is scrollable even if it does not have
  /// sufficient content to actually scroll. Otherwise, by default the user can
  /// only scroll the view if it has sufficient content. See [physics].
  ///
  /// On iOS, this also identifies the scroll view that will scroll to top in
  /// response to a tap in the status bar.
  ///
  /// Defaults to true when [scrollDirection] is [Axis.vertical] and
  /// [controller] is null.
  final bool primary;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions. Furthermore, if [primary] is
  /// false, then the user cannot scroll if there is insufficient content to
  /// scroll, while if [primary] is true, they can always attempt to scroll.
  ///
  /// To force the scroll view to always be scrollable even if there is
  /// insufficient content, as if [primary] was true but without necessarily
  /// setting it to true, provide an [AlwaysScrollableScrollPhysics] physics
  /// object, as in:
  ///
  /// ```dart
  ///   physics: const AlwaysScrollableScrollPhysics(),
  /// ```
  ///
  /// To force the scroll view to use the default platform conventions and not
  /// be scrollable if there is insufficient content, regardless of the value of
  /// [primary], provide an explicit [ScrollPhysics] object, as in:
  ///
  /// ```dart
  ///   physics: const ScrollPhysics(),
  /// ```
  ///
  /// The physics can be changed dynamically (by providing a new object in a
  /// subsequent build), but new physics will only take effect if the _class_ of
  /// the provided object changes. Merely constructing a new instance with a
  /// different configuration is insufficient to cause the physics to be
  /// reapplied. (This is because the final object used is generated
  /// dynamically, which can be relatively expensive, and it would be
  /// inefficient to speculatively create this object each frame to see if the
  /// physics should be updated.)
  final ScrollPhysics physics;

  /// Whether the extent of the scroll view in the [scrollDirection] should be
  /// determined by the contents being viewed.
  ///
  /// If the scroll view does not shrink wrap, then the scroll view will expand
  /// to the maximum allowed size in the [scrollDirection]. If the scroll view
  /// has unbounded constraints in the [scrollDirection], then [shrinkWrap] must
  /// be true.
  ///
  /// Shrink wrapping the content of the scroll view is significantly more
  /// expensive than expanding to the maximum allowed size because the content
  /// can expand and contract during scrolling, which means the size of the
  /// scroll view needs to be recomputed whenever the scroll position changes.
  ///
  /// Defaults to false.
  final bool shrinkWrap;

  /// Returns the [AxisDirection] in which the scroll view scrolls.
  ///
  /// Combines the [scrollDirection] with the [reverse] boolean to obtain the
  /// concrete [AxisDirection].
  ///
  /// If the [scrollDirection] is [Axis.horizontal], the ambient
  /// [Directionality] is also considered when selecting the concrete
  /// [AxisDirection]. For example, if the ambient [Directionality] is
  /// [TextDirection.rtl], then the non-reversed [AxisDirection] is
  /// [AxisDirection.left] and the reversed [AxisDirection] is
  /// [AxisDirection.right].
  @protected
  AxisDirection getDirection(BuildContext context) {
    return getAxisDirectionFromAxisReverseAndDirectionality(context, scrollDirection, reverse);
  }

  /// Build the list of widgets to place inside the viewport.
  ///
  /// Subclasses should override this method to build the slivers for the inside
  /// of the viewport.
  @protected
  List<Widget> buildSlivers(BuildContext context);

  /// Build the viewport.
  ///
  /// Subclasses may override this method to change how the viewport is built.
  /// The default implementation uses a [ShrinkWrappingViewport] if [shrinkWrap]
  /// is true, and a regular [Viewport] otherwise.
  @protected
  Widget buildViewport(
    BuildContext context,
    ViewportOffset offset,
    AxisDirection axisDirection,
    List<Widget> slivers,
  ) {
    if (shrinkWrap) {
      return new ShrinkWrappingViewport(
        axisDirection: axisDirection,
        offset: offset,
        slivers: slivers,
      );
    }
    return new Viewport(
      axisDirection: axisDirection,
      offset: offset,
      slivers: slivers,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> slivers = buildSlivers(context);
    final AxisDirection axisDirection = getDirection(context);

    final ScrollController scrollController = primary
        ? PrimaryScrollController.of(context)
        : controller;
    final Scrollable scrollable = new Scrollable(
      axisDirection: axisDirection,
      controller: scrollController,
      physics: physics,
      viewportBuilder: (BuildContext context, ViewportOffset offset) {
        return buildViewport(context, offset, axisDirection, slivers);
      },
    );
    return primary && scrollController != null
      ? new PrimaryScrollController.none(child: scrollable)
      : scrollable;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new EnumProperty<Axis>('scrollDirection', scrollDirection));
    description.add(new FlagProperty('reverse', value: reverse, ifTrue: 'reversed', showName: true));
    description.add(new DiagnosticsProperty<ScrollController>('controller', controller, showName: false, defaultValue: null));
    description.add(new FlagProperty('primary', value: primary, ifTrue: 'using primary controller', showName: true));
    description.add(new DiagnosticsProperty<ScrollPhysics>('physics', physics, showName: false, defaultValue: null));
    description.add(new FlagProperty('shrinkWrap', value: shrinkWrap, ifTrue: 'shrink-wrapping', showName: true));
  }
}

/// A [ScrollView] that creates custom scroll effects using slivers.
///
/// A [CustomScrollView] lets you supply [slivers] directly to create various
/// scrolling effects, such as lists, grids, and expanding headers. For example,
/// to create a scroll view that contains an expanding app bar followed by a
/// list and a grid, use a list of three slivers: [SliverAppBar], [SliverList],
/// and [SliverGrid].
///
/// [Widget]s in these [slivers] must produce [RenderSliver] objects.
///
/// To control the initial scroll offset of the scroll view, provide a
/// [controller] with its [ScrollController.initialScrollOffset] property set.
///
/// ## Sample code
///
/// This sample code shows a scroll view that contains a flexible pinned app
/// bar, a grid, and an infinite list.
///
/// ```dart
/// new CustomScrollView(
///   slivers: <Widget>[
///     const SliverAppBar(
///       pinned: true,
///       expandedHeight: 250.0,
///       flexibleSpace: const FlexibleSpaceBar(
///         title: const Text('Demo'),
///       ),
///     ),
///     new SliverGrid(
///       gridDelegate: new SliverGridDelegateWithMaxCrossAxisExtent(
///         maxCrossAxisExtent: 200.0,
///         mainAxisSpacing: 10.0,
///         crossAxisSpacing: 10.0,
///         childAspectRatio: 4.0,
///       ),
///       delegate: new SliverChildBuilderDelegate(
///         (BuildContext context, int index) {
///           return new Container(
///             alignment: Alignment.center,
///             color: Colors.teal[100 * (index % 9)],
///             child: new Text('grid item $index'),
///           );
///         },
///         childCount: 20,
///       ),
///     ),
///     new SliverFixedExtentList(
///       itemExtent: 50.0,
///       delegate: new SliverChildBuilderDelegate(
///         (BuildContext context, int index) {
///           return new Container(
///             alignment: Alignment.center,
///             color: Colors.lightBlue[100 * (index % 9)],
///             child: new Text('list item $index'),
///           );
///         },
///       ),
///     ),
///   ],
/// )
/// ```
///
/// See also:
///
///  * [SliverList], which is a sliver that displays linear list of children.
///  * [SliverFixedExtentList], which is a more efficient sliver that displays
///    linear list of children that have the same extent along the scroll axis.
///  * [SliverGrid], which is a sliver that displays a 2D array of children.
///  * [SliverPadding], which is a sliver that adds blank space around another
///    sliver.
///  * [SliverAppBar], which is a sliver that displays a header that can expand
///    and float as the scroll view scrolls.
///  * [ScrollNotification] and [NotificationListener], which can be used to watch
///    the scroll position without using a [ScrollController].
class CustomScrollView extends ScrollView {
  /// Creates a [ScrollView] that creates custom scroll effects using slivers.
  ///
  /// If the [primary] argument is true, the [controller] must be null.
  CustomScrollView({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    this.slivers: const <Widget>[],
  }) : super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
  );

  /// The slivers to place inside the viewport.
  final List<Widget> slivers;

  @override
  List<Widget> buildSlivers(BuildContext context) => slivers;
}

/// A [ScrollView] that uses a single child layout model.
///
/// See also:
///
///  * [ListView], which is a [BoxScrollView] that uses a linear layout model.
///  * [GridView], which is a [BoxScrollView] that uses a 2D layout model.
///  * [CustomScrollView], which can combine multiple child layout models into a
///    single scroll view.
abstract class BoxScrollView extends ScrollView {
  /// Creates a [ScrollView] uses a single child layout model.
  ///
  /// If the [primary] argument is true, the [controller] must be null.
  BoxScrollView({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    this.padding,
  }) : super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
  );

  /// The amount of space by which to inset the children.
  final EdgeInsetsGeometry padding;

  @override
  List<Widget> buildSlivers(BuildContext context) {
    Widget sliver = buildChildLayout(context);
    EdgeInsetsGeometry effectivePadding = padding;
    if (padding == null) {
      final MediaQueryData mediaQuery = MediaQuery.of(context, nullOk: true);
      if (mediaQuery != null) {
        // Automatically pad sliver with padding from MediaQuery.
        final EdgeInsets mediaQueryHorizontalPadding =
            mediaQuery.padding.copyWith(top: 0.0, bottom: 0.0);
        final EdgeInsets mediaQueryVerticalPadding =
            mediaQuery.padding.copyWith(left: 0.0, right: 0.0);
        // Consume the main axis padding with SliverPadding.
        effectivePadding = scrollDirection == Axis.vertical
            ? mediaQueryVerticalPadding
            : mediaQueryHorizontalPadding;
        // Leave behind the cross axis padding.
        sliver = new MediaQuery(
          data: mediaQuery.copyWith(
            padding: scrollDirection == Axis.vertical
                ? mediaQueryHorizontalPadding
                : mediaQueryVerticalPadding,
          ),
          child: sliver,
        );
      }
    }

    if (effectivePadding != null)
      sliver = new SliverPadding(padding: effectivePadding, sliver: sliver);
    return <Widget>[ sliver ];
  }

  /// Subclasses should override this method to build the layout model.
  @protected
  Widget buildChildLayout(BuildContext context);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: null));
  }
}

/// A scrollable list of widgets arranged linearly.
///
/// [ListView] is the most commonly used scrolling widget. It displays its
/// children one after another in the scroll direction. In the cross axis, the
/// children are required to fill the [ListView].
///
/// If non-null, the [itemExtent] forces the children to have the given extent
/// in the scroll direction. Specifying an [itemExtent] is more efficient than
/// letting the children determine their own extent because the scrolling
/// machinery can make use of the foreknowledge of the children's extent to save
/// work, for example when the scroll position changes drastically.
///
/// There are three options for constructing a [ListView]:
///
///  1. The default constructor takes an explicit [List<Widget>] of children. This
///     constructor is appropriate for list views with a small number of
///     children because constructing the [List] requires doing work for every
///     child that could possibly be displayed in the list view instead of just
///     those children that are actually visible.
///
///  2. The [ListView.builder] takes an [IndexedWidgetBuilder], which builds the
///     children on demand. This constructor is appropriate for list views with
///     a large (or infinite) number of children because the builder is called
///     only for those children that are actually visible.
///
///  3. The [ListView.custom] takes a [SliverChildDelegate], which provides the
///     ability to customize additional aspects of the child model. For example,
///     a [SliverChildDelegate] can control the algorithm used to estimate the
///     size of children that are not actually visible.
///
/// To control the initial scroll offset of the scroll view, provide a
/// [controller] with its [ScrollController.initialScrollOffset] property set.
///
/// ## Sample code
///
/// An infinite list of children:
///
/// ```dart
/// new ListView.builder(
///   padding: new EdgeInsets.all(8.0),
///   itemExtent: 20.0,
///   itemBuilder: (BuildContext context, int index) {
///     return new Text('entry $index');
///   },
/// )
/// ```
///
/// ## Transitioning to [CustomScrollView]
///
/// A [ListView] is basically a [CustomScrollView] with a single [SliverList] in
/// its [CustomScrollView.slivers] property.
///
/// If [ListView] is no longer sufficient, for example because the scroll view
/// is to have both a list and a grid, or because the list is to be combined
/// with a [SliverAppBar], etc, it is straight-forward to port code from using
/// [ListView] to using [CustomScrollView] directly.
///
/// The [key], [scrollDirection], [reverse], [controller], [primary], [physics],
/// and [shrinkWrap] properties on [ListView] map directly to the identically
/// named properties on [CustomScrollView].
///
/// The [CustomScrollView.slivers] property should be a list containing either a
/// [SliverList] or a [SliverFixedExtentList]; the former if [itemExtent] on the
/// [ListView] was null, and the latter if [itemExtent] was not null.
///
/// The [childrenDelegate] property on [ListView] corresponds to the
/// [SliverList.delegate] (or [SliverFixedExtentList.delegate]) property. The
/// [new ListView] constructor's `children` argument corresponds to the
/// [childrenDelegate] being a [SliverChildListDelegate] with that same
/// argument. The [new ListView.builder] constructor's `itemBuilder` and
/// `childCount` arguments correspond to the [childrenDelegate] being a
/// [SliverChildBuilderDelegate] with the matching arguments.
///
/// The [padding] property corresponds to having a [SliverPadding] in the
/// [CustomScrollView.slivers] property instead of the list itself, and having
/// the [SliverList] instead be a child of the [SliverPadding].
///
/// By default, [ListView] will automatically pad the list's scrollable
/// extremities to avoid partial obstructions indicated by [MediaQuery]'s
/// padding. To avoid this behavior, override with a zero [padding] property.
///
/// Once code has been ported to use [CustomScrollView], other slivers, such as
/// [SliverGrid] or [SliverAppBar], can be put in the [CustomScrollView.slivers]
/// list.
///
/// ### Sample code
///
/// Here are two brief snippets showing a [ListView] and its equivalent using
/// [CustomScrollView]:
///
/// ```dart
/// new ListView(
///   shrinkWrap: true,
///   padding: const EdgeInsets.all(20.0),
///   children: <Widget>[
///     const Text('I\'m dedicating every day to you'),
///     const Text('Domestic life was never quite my style'),
///     const Text('When you smile, you knock me out, I fall apart'),
///     const Text('And I thought I was so smart'),
///   ],
/// )
/// ```
///
/// ```dart
/// new CustomScrollView(
///   shrinkWrap: true,
///   slivers: <Widget>[
///     new SliverPadding(
///       padding: const EdgeInsets.all(20.0),
///       sliver: new SliverList(
///         delegate: new SliverChildListDelegate(
///           <Widget>[
///             const Text('I\'m dedicating every day to you'),
///             const Text('Domestic life was never quite my style'),
///             const Text('When you smile, you knock me out, I fall apart'),
///             const Text('And I thought I was so smart'),
///           ],
///         ),
///       ),
///     ),
///   ],
/// )
/// ```
///
/// See also:
///
///  * [SingleChildScrollView], which is a scrollable widget that has a single
///    child.
///  * [PageView], which is a scrolling list of child widgets that are each the
///    size of the viewport.
///  * [GridView], which is scrollable, 2D array of widgets.
///  * [CustomScrollView], which is a scrollable widget that creates custom
///    scroll effects using slivers.
///  * [ListBody], which arranges its children in a similar manner, but without
///    scrolling.
///  * [ScrollNotification] and [NotificationListener], which can be used to watch
///    the scroll position without using a [ScrollController].
class ListView extends BoxScrollView {
  /// Creates a scrollable, linear array of widgets from an explicit [List].
  ///
  /// This constructor is appropriate for list views with a small number of
  /// children because constructing the [List] requires doing work for every
  /// child that could possibly be displayed in the list view instead of just
  /// those children that are actually visible.
  ///
  /// It is usually more efficient to create children on demand using [new
  /// ListView.builder].
  ///
  /// The `addAutomaticKeepAlives` argument corresponds to the
  /// [SliverChildListDelegate.addAutomaticKeepAlives] property. The
  /// `addRepaintBoundaries` argument corresponds to the
  /// [SliverChildListDelegate.addRepaintBoundaries] property. Both must not be
  /// null.
  ListView({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsetsGeometry padding,
    this.itemExtent,
    bool addAutomaticKeepAlives: true,
    bool addRepaintBoundaries: true,
    List<Widget> children: const <Widget>[],
  }) : childrenDelegate = new SliverChildListDelegate(
         children,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
       ), super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  );

  /// Creates a scrollable, linear array of widgets that are created on demand.
  ///
  /// This constructor is appropriate for list views with a large (or infinite)
  /// number of children because the builder is called only for those children
  /// that are actually visible.
  ///
  /// Providing a non-null `itemCount` improves the ability of the [ListView] to
  /// estimate the maximum scroll extent.
  ///
  /// The `itemBuilder` callback will be called only with indices greater than
  /// or equal to zero and less than `itemCount`.
  ///
  /// The `itemBuilder` should actually create the widget instances when called.
  /// Avoid using a builder that returns a previously-constructed widget; if the
  /// list view's children are created in advance, or all at once when the
  /// [ListView] itself is created, it is more efficient to use [new ListView].
  /// Even more efficient, however, is to create the instances on demand using
  /// this constructor's `itemBuilder` callback.
  ///
  /// The `addAutomaticKeepAlives` argument corresponds to the
  /// [SliverChildBuilderDelegate.addAutomaticKeepAlives] property. The
  /// `addRepaintBoundaries` argument corresponds to the
  /// [SliverChildBuilderDelegate.addRepaintBoundaries] property. Both must not
  /// be null.
  ListView.builder({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsetsGeometry padding,
    this.itemExtent,
    @required IndexedWidgetBuilder itemBuilder,
    int itemCount,
    bool addAutomaticKeepAlives: true,
    bool addRepaintBoundaries: true,
  }) : childrenDelegate = new SliverChildBuilderDelegate(
         itemBuilder,
         childCount: itemCount,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
       ), super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  );

  /// Creates a scrollable, linear array of widgets with a custom child model.
  ///
  /// For example, a custom child model can control the algorithm used to
  /// estimate the size of children that are not actually visible.
  ListView.custom({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsetsGeometry padding,
    this.itemExtent,
    @required this.childrenDelegate,
  }) : assert(childrenDelegate != null),
       super(
         key: key,
         scrollDirection: scrollDirection,
         reverse: reverse,
         controller: controller,
         primary: primary,
         physics: physics,
         shrinkWrap: shrinkWrap,
         padding: padding,
       );

  /// If non-null, forces the children to have the given extent in the scroll
  /// direction.
  ///
  /// Specifying an [itemExtent] is more efficient than letting the children
  /// determine their own extent because the scrolling machinery can make use of
  /// the foreknowledge of the children's extent to save work, for example when
  /// the scroll position changes drastically.
  final double itemExtent;

  /// A delegate that provides the children for the [ListView].
  ///
  /// The [ListView.custom] constructor lets you specify this delegate
  /// explicitly. The [ListView] and [ListView.builder] constructors create a
  /// [childrenDelegate] that wraps the given [List] and [IndexedWidgetBuilder],
  /// respectively.
  final SliverChildDelegate childrenDelegate;

  @override
  Widget buildChildLayout(BuildContext context) {
    if (itemExtent != null) {
      return new SliverFixedExtentList(
        delegate: childrenDelegate,
        itemExtent: itemExtent,
      );
    }
    return new SliverList(delegate: childrenDelegate);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new DoubleProperty('itemExtent', itemExtent, defaultValue: null));
  }
}

/// A scrollable, 2D array of widgets.
///
/// The main axis direction of a grid is the direction in which it scrolls (the
/// [scrollDirection]).
///
/// The most commonly used grid layouts are [GridView.count], which creates a
/// layout with a fixed number of tiles in the cross axis, and
/// [GridView.extent], which creates a layout with tiles that have a maximum
/// cross-axis extent. A custom [SliverGridDelegate] can produce an arbitrary 2D
/// arrangement of children, including arrangements that are unaligned or
/// overlapping.
///
/// To create a grid with a large (or infinite) number of children, use the
/// [GridView.builder] constructor with either a
/// [SliverGridDelegateWithFixedCrossAxisCount] or a
/// [SliverGridDelegateWithMaxCrossAxisExtent] for the [gridDelegate].
///
/// To use a custom [SliverChildDelegate], use [GridView.custom].
///
/// To create a linear array of children, use a [ListView].
///
/// To control the initial scroll offset of the scroll view, provide a
/// [controller] with its [ScrollController.initialScrollOffset] property set.
///
/// ## Transitioning to [CustomScrollView]
///
/// A [GridView] is basically a [CustomScrollView] with a single [SliverGrid] in
/// its [CustomScrollView.slivers] property.
///
/// If [GridView] is no longer sufficient, for example because the scroll view
/// is to have both a grid and a list, or because the grid is to be combined
/// with a [SliverAppBar], etc, it is straight-forward to port code from using
/// [GridView] to using [CustomScrollView] directly.
///
/// The [key], [scrollDirection], [reverse], [controller], [primary], [physics],
/// and [shrinkWrap] properties on [GridView] map directly to the identically
/// named properties on [CustomScrollView].
///
/// The [CustomScrollView.slivers] property should be a list containing just a
/// [SliverGrid].
///
/// The [childrenDelegate] property on [GridView] corresponds to the
/// [SliverGrid.delegate] property, and the [gridDelegate] property on the
/// [GridView] corresponds to the [SliverGrid.gridDelegate] property.
///
/// The [new GridView], [new GridView.count], and [new GridView.extent]
/// constructors' `children` arguments correspond to the [childrenDelegate]
/// being a [SliverChildListDelegate] with that same argument. The [new
/// GridView.builder] constructor's `itemBuilder` and `childCount` arguments
/// correspond to the [childrenDelegate] being a [SliverChildBuilderDelegate]
/// with the matching arguments.
///
/// The [new GridView.count] and [new GridView.extent] constructors create
/// custom grid delegates, and have equivalently named constructors on
/// [SliverGrid] to ease the transition: [new SliverGrid.count] and [new
/// SliverGrid.extent] respectively.
///
/// The [padding] property corresponds to having a [SliverPadding] in the
/// [CustomScrollView.slivers] property instead of the grid itself, and having
/// the [SliverGrid] instead be a child of the [SliverPadding].
///
/// By default, [ListView] will automatically pad the list's scrollable
/// extremities to avoid partial obstructions indicated by [MediaQuery]'s
/// padding. To avoid this behavior, override with a zero [padding] property.
///
/// Once code has been ported to use [CustomScrollView], other slivers, such as
/// [SliverList] or [SliverAppBar], can be put in the [CustomScrollView.slivers]
/// list.
///
/// ### Sample code
///
/// Here are two brief snippets showing a [GridView] and its equivalent using
/// [CustomScrollView]:
///
/// ```dart
/// new GridView.count(
///   primary: false,
///   padding: const EdgeInsets.all(20.0),
///   crossAxisSpacing: 10.0,
///   crossAxisCount: 2,
///   children: <Widget>[
///     const Text('He\'d have you all unravel at the'),
///     const Text('Heed not the rabble'),
///     const Text('Sound of screams but the'),
///     const Text('Who scream'),
///     const Text('Revolution is coming...'),
///     const Text('Revolution, they...'),
///   ],
/// )
/// ```
///
/// ```dart
/// new CustomScrollView(
///   primary: false,
///   slivers: <Widget>[
///     new SliverPadding(
///       padding: const EdgeInsets.all(20.0),
///       sliver: new SliverGrid.count(
///         crossAxisSpacing: 10.0,
///         crossAxisCount: 2,
///         children: <Widget>[
///           const Text('He\'d have you all unravel at the'),
///           const Text('Heed not the rabble'),
///           const Text('Sound of screams but the'),
///           const Text('Who scream'),
///           const Text('Revolution is coming...'),
///           const Text('Revolution, they...'),
///         ],
///       ),
///     ),
///   ],
/// )
/// ```
///
/// See also:
///
///  * [SingleChildScrollView], which is a scrollable widget that has a single
///    child.
///  * [ListView], which is scrollable, linear list of widgets.
///  * [PageView], which is a scrolling list of child widgets that are each the
///    size of the viewport.
///  * [CustomScrollView], which is a scrollable widget that creates custom
///    scroll effects using slivers.
///  * [SliverGridDelegateWithFixedCrossAxisCount], which creates a layout with
///    a fixed number of tiles in the cross axis.
///  * [SliverGridDelegateWithMaxCrossAxisExtent], which creates a layout with
///    tiles that have a maximum cross-axis extent.
///  * [ScrollNotification] and [NotificationListener], which can be used to watch
///    the scroll position without using a [ScrollController].
class GridView extends BoxScrollView {
  /// Creates a scrollable, 2D array of widgets with a custom
  /// [SliverGridDelegate].
  ///
  /// The [gridDelegate] argument must not be null.
  ///
  /// The `addAutomaticKeepAlives` argument corresponds to the
  /// [SliverChildListDelegate.addAutomaticKeepAlives] property. The
  /// `addRepaintBoundaries` argument corresponds to the
  /// [SliverChildListDelegate.addRepaintBoundaries] property. Both must not be
  /// null.
  GridView({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsetsGeometry padding,
    @required this.gridDelegate,
    bool addAutomaticKeepAlives: true,
    bool addRepaintBoundaries: true,
    List<Widget> children: const <Widget>[],
  }) : assert(gridDelegate != null),
       childrenDelegate = new SliverChildListDelegate(
         children,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
       ),
       super(
         key: key,
         scrollDirection: scrollDirection,
         reverse: reverse,
         controller: controller,
         primary: primary,
         physics: physics,
         shrinkWrap: shrinkWrap,
         padding: padding,
       );

  /// Creates a scrollable, 2D array of widgets that are created on demand.
  ///
  /// This constructor is appropriate for grid views with a large (or infinite)
  /// number of children because the builder is called only for those children
  /// that are actually visible.
  ///
  /// Providing a non-null `itemCount` improves the ability of the [GridView] to
  /// estimate the maximum scroll extent.
  ///
  /// `itemBuilder` will be called only with indices greater than or equal to
  /// zero and less than `itemCount`.
  ///
  /// The [gridDelegate] argument must not be null.
  ///
  /// The `addAutomaticKeepAlives` argument corresponds to the
  /// [SliverChildBuilderDelegate.addAutomaticKeepAlives] property. The
  /// `addRepaintBoundaries` argument corresponds to the
  /// [SliverChildBuilderDelegate.addRepaintBoundaries] property. Both must not
  /// be null.
  GridView.builder({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsetsGeometry padding,
    @required this.gridDelegate,
    @required IndexedWidgetBuilder itemBuilder,
    int itemCount,
    bool addAutomaticKeepAlives: true,
    bool addRepaintBoundaries: true,
  }) : assert(gridDelegate != null),
       childrenDelegate = new SliverChildBuilderDelegate(
         itemBuilder,
         childCount: itemCount,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
       ),
       super(
         key: key,
         scrollDirection: scrollDirection,
         reverse: reverse,
         controller: controller,
         primary: primary,
         physics: physics,
         shrinkWrap: shrinkWrap,
         padding: padding,
       );

  /// Creates a scrollable, 2D array of widgets with both a custom
  /// [SliverGridDelegate] and a custom [SliverChildDelegate].
  ///
  /// To use an [IndexedWidgetBuilder] callback to build children, either use
  /// a [SliverChildBuilderDelegate] or use the [GridView.builder] constructor.
  ///
  /// The [gridDelegate] and [childrenDelegate] arguments must not be null.
  GridView.custom({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsetsGeometry padding,
    @required this.gridDelegate,
    @required this.childrenDelegate,
  }) : assert(gridDelegate != null),
       assert(childrenDelegate != null),
       super(
         key: key,
         scrollDirection: scrollDirection,
         reverse: reverse,
         controller: controller,
         primary: primary,
         physics: physics,
         shrinkWrap: shrinkWrap,
         padding: padding,
       );

  /// Creates a scrollable, 2D array of widgets with a fixed number of tiles in
  /// the cross axis.
  ///
  /// Uses a [SliverGridDelegateWithFixedCrossAxisCount] as the [gridDelegate].
  ///
  /// The `addAutomaticKeepAlives` argument corresponds to the
  /// [SliverChildListDelegate.addAutomaticKeepAlives] property. The
  /// `addRepaintBoundaries` argument corresponds to the
  /// [SliverChildListDelegate.addRepaintBoundaries] property. Both must not be
  /// null.
  ///
  /// See also:
  ///
  ///  * [new SliverGrid.count], the equivalent constructor for [SliverGrid].
  GridView.count({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsetsGeometry padding,
    @required int crossAxisCount,
    double mainAxisSpacing: 0.0,
    double crossAxisSpacing: 0.0,
    double childAspectRatio: 1.0,
    bool addAutomaticKeepAlives: true,
    bool addRepaintBoundaries: true,
    List<Widget> children: const <Widget>[],
  }) : gridDelegate = new SliverGridDelegateWithFixedCrossAxisCount(
         crossAxisCount: crossAxisCount,
         mainAxisSpacing: mainAxisSpacing,
         crossAxisSpacing: crossAxisSpacing,
         childAspectRatio: childAspectRatio,
       ),
       childrenDelegate = new SliverChildListDelegate(
         children,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
       ), super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  );

  /// Creates a scrollable, 2D array of widgets with tiles that each have a
  /// maximum cross-axis extent.
  ///
  /// Uses a [SliverGridDelegateWithMaxCrossAxisExtent] as the [gridDelegate].
  ///
  /// The `addAutomaticKeepAlives` argument corresponds to the
  /// [SliverChildListDelegate.addAutomaticKeepAlives] property. The
  /// `addRepaintBoundaries` argument corresponds to the
  /// [SliverChildListDelegate.addRepaintBoundaries] property. Both must not be
  /// null.
  ///
  /// See also:
  ///
  ///  * [new SliverGrid.extent], the equivalent constructor for [SliverGrid].
  GridView.extent({
    Key key,
    Axis scrollDirection: Axis.vertical,
    bool reverse: false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap: false,
    EdgeInsetsGeometry padding,
    @required double maxCrossAxisExtent,
    double mainAxisSpacing: 0.0,
    double crossAxisSpacing: 0.0,
    double childAspectRatio: 1.0,
    bool addAutomaticKeepAlives: true,
    bool addRepaintBoundaries: true,
    List<Widget> children: const <Widget>[],
  }) : gridDelegate = new SliverGridDelegateWithMaxCrossAxisExtent(
         maxCrossAxisExtent: maxCrossAxisExtent,
         mainAxisSpacing: mainAxisSpacing,
         crossAxisSpacing: crossAxisSpacing,
         childAspectRatio: childAspectRatio,
       ),
       childrenDelegate = new SliverChildListDelegate(
         children,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
       ), super(
    key: key,
    scrollDirection: scrollDirection,
    reverse: reverse,
    controller: controller,
    primary: primary,
    physics: physics,
    shrinkWrap: shrinkWrap,
    padding: padding,
  );

  /// A delegate that controls the layout of the children within the [GridView].
  ///
  /// The [GridView] and [GridView.custom] constructors let you specify this
  /// delegate explicitly. The other constructors create a [gridDelegate]
  /// implicitly.
  final SliverGridDelegate gridDelegate;

  /// A delegate that provides the children for the [GridView].
  ///
  /// The [GridView.custom] constructor lets you specify this delegate
  /// explicitly. The other constructors create a [childrenDelegate] that wraps
  /// the given child list.
  final SliverChildDelegate childrenDelegate;

  @override
  Widget buildChildLayout(BuildContext context) {
    return new SliverGrid(
      delegate: childrenDelegate,
      gridDelegate: gridDelegate,
    );
  }
}
