
class Transformation {
    // Class for one of the contractive transformations that control the fractal
    PVector fixedPoint; // The fixed point of the transformation, seen on the screen
    float scaleFactor; // Scale factor of the transformation
    float rotateFactor; // Angle by which the transformation rotates
    boolean active; // Boolean describes whether the transformation is currently being edited by the user on the screen
    float scaleFactorIncreaseRate = 1.1; // rate at which scale factor is increased and decreased by user controls
    float rotateFactorIncreaseRate = 0.1*PI;
    Transformation(PVector fp, float sc, float rt){
        fixedPoint = fp;
        scaleFactor = sc;
        rotateFactor = rt;
        active = false;
    }
    PVector apply(PVector v){
        // Applies the transformation to a vector v that describes a location on the screen
        // First subtracts the fixed point, then applies scaling and rotation, then adds back the fixed point
        PVector vOut = v.copy();
        vOut.sub(fixedPoint);
        vOut.mult(scaleFactor);
        vOut.rotate(rotateFactor);
        vOut.add(fixedPoint);
        return vOut;
    }
    void drawPoint(){
        // Draws the red control point on the screen that visually describes scale factor and rotation factor
        noStroke();
        fill(150, 0, 0);
        ellipse(fixedPoint.x, fixedPoint.y, 20*scaleFactor, 20*scaleFactor);
        stroke(255);
        PVector lineTo = new PVector(1.0, 0.0); // Endpoint of the white line describing rotation factor
        lineTo.rotate(rotateFactor);
        lineTo.mult(scaleFactor*20);
        lineTo.add(fixedPoint);
        line(fixedPoint.x, fixedPoint.y, lineTo.x, lineTo.y);
    }
    void increaseScaleFactor(){
        // Increases scale factor by a constant multiple, while keeping it below 1
        if(scaleFactor < 1.0){
            scaleFactor *= scaleFactorIncreaseRate;
        }    
    }
    void decreaseScaleFactor(){
        // Decreases scale factor by a constant multiple
        scaleFactor /= scaleFactorIncreaseRate;
    }
    void increaseRotateFactor(){
        // Increases rotate factor by adding a constant, normalizing between -PI and PI
        rotateFactor += rotateFactorIncreaseRate;
        if(rotateFactor >= PI){
            rotateFactor -= 2*PI;
        }
    }
    void decreaseRotateFactor(){
        // Decreases rotate factor by adding a constant, normalizing between -PI and PI
        rotateFactor -= rotateFactorIncreaseRate;
        if(rotateFactor <= -PI){
            rotateFactor += 2*PI;
        }    
    }

}

PShape makeShape(ArrayList<PVector> vertices){
    // Make a shape from a list of vertices, used to draw each triangle on the screen
    PShape sh = createShape();
    sh.beginShape();
    sh.noStroke();
    sh.fill(0, 255);
    for(PVector v : vertices){
        sh.vertex(v.x, v.y);
    }
    sh.endShape(CLOSE);
    return sh;
}

void makeFractal(ArrayList<Transformation> transformations, ArrayList<PVector> vertices, int depth){
    // Main recursive fractal making function, takes in an initial shape (vertices) and the set of tranformations
    //      as well as the depth to which the fractal should be approximated
    if(depth == 0){ // simply make the triangle specified by the vertices (to be drawn to screen)
        fractal.add(makeShape(vertices));
    } else {
        for(Transformation tr: transformations){
            // Apply each transformation to the shape specified by "vertices", and make the recursive call
            ArrayList<PVector> newVertices = new ArrayList<PVector>();
            for(PVector v: vertices){
                PVector vOut = tr.apply(v);
                newVertices.add(vOut);
            }
            makeFractal(transformations, newVertices, depth-1); // recursive call
        }
    }
}

ArrayList<PVector> fixedPoints = new ArrayList<PVector>(); // fixed control points of the transformations
ArrayList<Transformation> transformations = new ArrayList<Transformation>(); // the transformations (scaling and rotation)
ArrayList<PShape> fractal = new ArrayList<PShape>(); // list of triangles to be drawn, so we don't need to recompute each frame
Transformation activeTransformation; // which of the transformations is undergoing user control
int activeTransformationIndex; // index of the active transformation
int depth = 5; // initial depth of fractal recursion
boolean updated = true; // sets to true when fractal needs to be recomputed


void setup() {
    size(700,700,P2D);
    // set up initial fixed points
    fixedPoints.add(new PVector(width/2, height/2 - 200));
    fixedPoints.add(new PVector(width/4, height/2 + 200));
    fixedPoints.add(new PVector(3*width/4, height/2 + 200));
    // set up initial transformations
    for(PVector fp : fixedPoints){
        transformations.add(new Transformation(fp, 0.5, 0.0));
    }
    // choose an arbitrary active transformation
    activeTransformation = transformations.get(0);
    activeTransformationIndex = 0;
}


void draw(){

    background(200, 200, 255);

    for(PShape sh: fractal){
        shape(sh); // draw the shapes in the fractal
    }

    activeTransformation.drawPoint(); // draw the control for the active fixed point

    text("Recursion depth: "+depth, 5, 15);
    text("Scale factor: "+String.format("%.2f", activeTransformation.scaleFactor), 5, 30);
    text("Rotate factor: "+String.format("%.2f", activeTransformation.rotateFactor), 5, 45);

    if(updated){ // recompute the triangle vertices
        fractal = new ArrayList<PShape>();
        makeFractal(transformations, new ArrayList<PVector>(fixedPoints.subList(0,Math.min(3, fixedPoints.size()))), depth);
    }

    updated = false;
}


void mousePressed(){
    // adds a new transformation by its fixed point
    fixedPoints.add(new PVector(mouseX, mouseY));
    transformations.add(new Transformation(new PVector(mouseX, mouseY), 0.5, 0.0));
    updated = true;
}

void keyPressed(){
    if (key == DELETE){ // remove active transformation
        fixedPoints.remove(activeTransformationIndex);
        transformations.remove(activeTransformationIndex);
        activeTransformation = transformations.get(0);
        activeTransformationIndex = 0;
    } else if (key == 'q'){
        activeTransformation.increaseScaleFactor();
    } else if (key == 'a'){
        activeTransformation.decreaseScaleFactor();
    } else if (key == 'w'){
        activeTransformation.increaseRotateFactor();
    } else if (key == 's'){
        activeTransformation.decreaseRotateFactor();
    } else if (key == 'e'){
        depth += 1;
    } else if (key == 'd'){
        if(depth >= 1){
            depth -= 1;
        }
    }
    updated = true;
}

void mouseMoved(){
    // check if a different transformation needs to be activated
    float dist; // distance to each fixed point
    for(int i = 0; i<transformations.size(); i++){
        Transformation tr = transformations.get(i);
        dist = (float)Math.sqrt(Math.pow((tr.fixedPoint.x - mouseX), 2)+Math.pow((tr.fixedPoint.y - mouseY), 2));
        if(dist < 20){ // if distance is less than 20, activate this transformation
            activeTransformation = tr;
            activeTransformationIndex = i;
        }
    }
}