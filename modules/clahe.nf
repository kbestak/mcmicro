// Import utility functions from lib/mcmicro/*.groovy
import mcmicro.*

// Process name will appear in the the nextflow execution log
// While not strictly required, it's a good idea to make the 
//   process name match your tool name to avoid user confusion
process clahe_seg_prep {

    // Use the container specification from the parameter file
    container "${params.contPfx}${module.container}:${module.version}"

    // Specify the project subdirectory for writing the outputs to
    // The pattern: specification must match the output: files below
    // Subdirectory: clahe
    publishDir "${params.in}/clahe", mode: 'copy', pattern: "${sampleName}_clahe.ome.tif"

    // Stores .command.sh and .command.log from the work directory
    //   to the project provenance
    // No change to this line is required
    publishDir "${Flow.QC(params.in, 'provenance')}", mode: 'copy', 
      pattern: '.command.{sh,log}',
      saveAs: {fn -> fn.replace('.command', "${module.name}-${task.index}")}
    
    // Inputs for the process
    // mcp - MCMICRO parameters (workflow, options, etc.)
    // module - module specifications (name, container, options, etc.)
    // path to the markers.csv
    // path to the registered image
  input:
    val mcp
    val module
    path(image)
    val sampleName

    // outputs are returned as results with appropriate patterns
  output:
    // Output clahe image
    path("${sampleName}_clahe.ome.tif"), emit: clahe_seg_prep
    // Provenance files
    tuple path('.command.sh'), path('.command.log')

    // Specifies whether to run the process
    // Here, we simply take the flag from the workflow parameters
  when: Flow.doirun('clahe', mcp.workflow)

    // The command to be executed inside the tool container
    // The command must write all outputs to the current working directory (.)
    // Opts.moduleOpts() will identify and return the appropriate module options
    """
    python3 /seg_prep/clahe_segmentation_prep.py --output ${sampleName}_clahe.ome.tif --input $image ${Opts.moduleOpts(module, mcp)}
    """
}
workflow clahe {
  
    // Inputs:
  take:
    mcp // MCMICRO parameters (workflow, options, etc.)
    image // image to apply clahe on
  main:
    // run the backsub process with the mcmicro parameters, module value
    // markers path and pre-registered image path
    sampleName = file(params.in).name
    clahe_seg_prep(mcp, mcp.modules['clahe'], image, sampleName)
    
    // Return the outputs produced by the tool
  emit:
    image = clahe_seg_prep.out.clahe_seg_prep
}
