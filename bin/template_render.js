var system = require('system'), fs = require('fs');
var page = require('webpage').create();

// Startup
if(system.args.length != 3) {
  console.log("Usage: template_render.js <template-id> <template-json>");
  phantom.exit(1);
}
// Uncomment to get debug
//page.onConsoleMessage = function(msg) {
//  system.stderr.writeLine('console: ' + msg);
//};

var saveLocation = "/data/web/current/public/images/templates/";
var templateId = system.args[1];
var json = system.args[2];

page.open("/vagrant/template-designer/app/render.html", function() {
  // We need to grab the svg element and add the ns attribute
  // Then we need to clone it into another element that supports innerHTML
  var svg_contents = page.evaluate(function(json) {
    // Load the template we were passed
    var templateDesigner = document.querySelectorAll(".template-designer");
    angular.element(templateDesigner).scope().loadTemplate(JSON.parse(json));

    var svg = document.querySelectorAll("svg")[0];

    // Get all children so we can figure out x and y
    // For now, we check rect and image
    var minX, maxX, minY, maxY, offsetRight, offsetBottom = null;
    var imageChildren = svg.querySelectorAll("image");
    var rectChildren = svg.querySelectorAll("rect");

    _.each([imageChildren, rectChildren], function(children) {
      _.each(children, function(child) {
        var x = parseInt(child.getAttribute("x"));
        var y = parseInt(child.getAttribute("y"));
        var width = parseInt(child.getAttribute("width"));
        var height = parseInt(child.getAttribute("height"));

        var rightX = x + width;
        var bottomY = y + height;

        if(!minX || x < minX) {
          minX = x;
        }
        if(!maxX || rightX > maxX) {
          maxX = rightX;
        }
        if(!minY || y < minY) {
          minY = y;
        }
        if(!maxY || bottomY > maxY) {
          maxY = bottomY;
        }
      });
    });

    var viewBox = (minX - 15) + " " + (minY - 15) + " " + ((maxX - minX) + 15) + " " + (maxY + 15);

    svg.setAttribute("xmlns", "http://www.w3.org/2000/svg");
    svg.setAttribute("xmlns:xlink", "http://www.w3.org/1999/xlink");
    svg.setAttribute("viewBox", viewBox);

    var el = document.createElement("div");
    el.appendChild(svg.cloneNode(true));

    return el.innerHTML;
  }, json);

  try {
    svg_contents = "<?xml version=\"1.0\"?>\n" + svg_contents.replace(/href/g, "xlink:href");

    // TODO: clean this up, foo
    var regexp = new RegExp("file:///data/web/current/app/assets/images", "g");
    svg_contents = svg_contents.replace(regexp, "/assets");

    fs.write(saveLocation + templateId + ".svg", svg_contents, 'w');
    console.log("Saved to " + saveLocation);
  } catch(e) {
    console.log(e);
  }

  phantom.exit();
});
