package
{
	import flare.analytics.graph.BetweennessCentrality;
	import flare.data.DataSet;
	import flare.data.DataSource;
	import flare.display.TextSprite;
	import flare.scale.ScaleType;
	import flare.util.Shapes;
	import flare.util.palette.ColorPalette;
	import flare.vis.Visualization;
	import flare.vis.controls.DragControl;
	import flare.vis.controls.ExpandControl;
	import flare.vis.controls.PanZoomControl;
	import flare.vis.data.Data;
	import flare.vis.data.DataSprite;
	import flare.vis.data.NodeSprite;
	import flare.vis.operator.OperatorList;
	import flare.vis.operator.encoder.ColorEncoder;
	import flare.vis.operator.encoder.SizeEncoder;
	import flare.vis.operator.filter.VisibilityFilter;
	import flare.vis.operator.label.Labeler;
	import flare.vis.operator.layout.Layout;
	import flare.vis.operator.layout.NodeLinkTreeLayout;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;

    [SWF(width="800", height="800", backgroundColor="#ffffff", frameRate="30")]
	public class GraphLayout extends Sprite
	{
 		// Visualization is the generic class for representing an interactive data visualization
		// We will use Visualization class to generate graphs (in this example)
		//
		// In this example:
		//     - Attache controllers to vis
		private var vis:Visualization;
		private var loader:URLLoader;
 
        public function GraphLayout()
        {
        	stage.align = StageAlign.TOP_LEFT;
        	stage.scaleMode = StageScaleMode.NO_SCALE;
            loadData();
        }
 
        private function loadData():void
        {
            var ds:DataSource = new DataSource( "testing_graph.xml", "graphml" );
            loader = ds.load();
            loader.addEventListener( Event.COMPLETE, processData );
        }
 
 		private function processData( evt:Event ):void
        {
    		trace("Done");
            var dataSet:DataSet = loader.data as DataSet;
            
            visualize( Data.fromDataSet( dataSet ) );
   		}
 
        private function visualize( data:Data ):void
        {
        	// Add 'vis' to display list
        	vis = new Visualization( data );
            vis.bounds = new Rectangle( 0, 0, 600, 750 );
            vis.graphics.lineStyle( 0 );
            vis.graphics.drawRect( 0, 0, 600, 750 );
            vis.x = 100;
            vis.y = 25;
            this.addChild( vis );
            
            // Define edge and node properties
            data.edges[ "lineWidth" ] = 1;
//            data.nodes.setProperties( { fillAlpha: 0, lineAlpha: 0 } );
            data.nodes.setProperties( { fillAlpha: 1, lineAlpha: 0, shape: Shapes.CIRCLE, size: 1.5 } );
            
			// Three ways to apply operators to vis
            var treeLayout:Layout = new NodeLinkTreeLayout();
			
			// Method #1
			// Un-named operators
			vis.operators.add( treeLayout );
//			vis.update();
			
			// Method #2
			// Named operators
//			vis.setOperator( "tree", treeLayout );
//			vis.update( null, "tree" );
			
			// Method #3
			// Apply operator to a Visualization object once
//            treeLayout.visualization = vis;
//            treeLayout.operate();
            
            // Remove all un-named operators
//			vis.operators.clear();

			// Apply force-directed layout
			// Be sure to exclude NodeLinkTreeLayout() from un-named/automaticaly updated operator list
//			vis.operators.add( new ForceDirectedLayout( true ) );
//			vis.continuousUpdates = true;
            
            // Add controls to Visualization
			vis.controls.add( new DragControl( NodeSprite ) );  
			vis.controls.add( new PanZoomControl( vis ) );
			vis.controls.add( new ExpandControl( ) );  // Requires un-named NodeLinkTreeLayout()
            vis.update();
			
			// Displays hand-cursor
			vis.data.nodes[ "buttonMode" ] = true;
			
            // Add labels to the graph
            addLabels();

			// Color the nodes
			colorNodes();
			colorEdges();
			//colorByCentrality();
			
			//playing with filters
			vis.setOperator("filter", new VisibilityFilter(filter));
			vis.update(null, "filter").play();
        }
        
        private function filter(d:DataSprite):Boolean {
        	var id:String = String(d.data["id"]).toLowerCase();
        	var source:String = String(d.data["source"]).toLowerCase();
        	var target:String = String(d.data["target"]).toLowerCase();
        	
        	if (id == "flare.analytics" || source == "flare.analytics" || target == "flare.analytics")
        		return false;
        	return true;
        }
        
		private function addLabels():void
		{
			var labeler:Labeler = new Labeler( "data.id" );
			labeler.textMode = TextSprite.DEVICE;
			vis.setOperator( "labels", labeler );
			vis.update( null, "labels" );
		}
		
		private function colorNodes():void
		{
			vis.setOperator( "size", 
				new OperatorList(
					new SizeEncoder( "data.lines", Data.NODES ),
					new ColorEncoder( "data.tutorial", Data.NODES, "fillColor", ScaleType.CATEGORIES )
				)
			);
            vis.update( 2, "size" ).play();
		}
				
		private function colorEdges():void 
		{
			var colors:Array = [0xffffffff, 0xff000000];
			vis.setOperator( "edgeColor", new OperatorList(new ColorEncoder("data.hidden", Data.EDGES, "lineColor", ScaleType.CATEGORIES, ColorPalette.category(2, colors, 1.0))));
			vis.update(null, "edgeColor").play();
		}		
				
		private function colorByCentrality():void
		{
			// The Centrality algorithm due to Ulrik Brandes, 
			// as published in the Journal of Mathematical Sociology, 25(2):163-177, 2001.
			
			// Create a named set of operaters using OperatorList 
			vis.setOperator( "centrality", 
				new OperatorList(
            		new BetweennessCentrality(),
            		new ColorEncoder( "props.centrality", Data.NODES, "props.label.color", ScaleType.LINEAR, ColorPalette.ramp(0xff000000, 0xffff0088) )
            	)
            );
            vis.update( 2, "centrality" ).play();
		}
	}
}