library(shiny)
library(dplyr)
library(ggplot2)
library(ggnewscale)

# Workaround for Google Chrome bug (blob URL downloads from webR/shinylive)
downloadButton <- function(...) {
  tag <- shiny::downloadButton(...)
  tag$attribs$download <- NULL
  tag
}

# Scenario choices and the Target FOV (deg) that each one sets
scenario_fov <- c("Savanna and scrubland"                = 60,
                  "Closed-canopy forest"                 = 60,
                  "Tall canopies / complex topography"   = 40,
                  "Flooded forests / extreme topography" = 30)

# Scenario choices and the max canopy height that each one sets
scenario_height <- c("Savanna and scrubland"             = 25,
                     "Closed-canopy forest"                 = 35,
                     "Tall canopies / complex topography"   = 50,
                     "Flooded forests / extreme topography" = 50)

ui <- fluidPage(
  titlePanel("GEO-TREES ALS flightline visualization"),
  
  sidebarLayout(
    sidebarPanel(
      textInput("name", "Site name:", "Site name"),
      textInput("sensor", "Sensor:", "Sensor"),
      sliderInput("FOV", "Sensor FOV (deg):", min = 0, max = 180, value = 50, step = 1),
      numericInput("alt", "Altitude (m):", 700),
      sliderInput("overlap", "Overlap (%):", min = 0, max = 100, value = 50, step = 5),
      selectInput("scenario", "Scenario", choices = names(scenario_fov)),
      sliderInput("FOV_target", "Target FOV (deg):", min = 0, max = 180,
                  value = unname(scenario_fov[1]), step = 5),
      numericInput("canopy_max", "Maximum canopy height (m):", 
                   value = unname(scenario_height[1])),
      downloadButton("downloadPlot", "Download plot")
      
    ),
    
    mainPanel(
      plotOutput("overlapPlot", height = "800px")
    )
  )
)

server <- function(input, output, session) {
  
  # Set the Target FOV and the maximum canopy height whenever a scenario is selected
  observeEvent(input$scenario, {
    updateSliderInput(session, "FOV_target", value = unname(scenario_fov[input$scenario]))
    updateNumericInput(session, "canopy_max", value = unname(scenario_height[input$scenario]))
  })
  
  # Reactive calculations to update when inputs change
  plot_data <- reactive({
    
    # Overlap slider is in percent (0-100); the calculations below use a 0-1 fraction
    overlap_prop <- input$overlap / 100
    
    # Angles
    angle_rad <- (input$FOV / 2) * pi / 180
    angle_rad_target <- (input$FOV_target / 2) * pi / 180
    SF_canopy <- (input$alt - input$canopy_max) / input$alt
    
    # Swath Widths
    half_swath <- tan(angle_rad) * input$alt
    half_swath_target <- tan(angle_rad_target) * input$alt
    half_swath_canopy <- half_swath * SF_canopy
    half_swath_target_canopy <- half_swath_target * SF_canopy
    
    # Plotting Locations
    overlap_distance <- half_swath * 2 * overlap_prop
    X_1 <- half_swath
    X_2 <- (half_swath * 3) - overlap_distance
    X_3 <- (half_swath * 5) - (overlap_distance * 2)
    
    # Overlaps
    overlap_target <- ((X_1 + half_swath_target) - (X_2 - half_swath_target)) / (half_swath_target * 2)
    overlap_canopy <- ((X_1 + half_swath_canopy) - (X_2 - half_swath_canopy)) / (half_swath_canopy * 2)
    overlap_target_canopy <- ((X_1 + half_swath_target_canopy) - (X_2 - half_swath_target_canopy)) / (half_swath_target_canopy * 2)
    
    # Dataframes
    tri <- data.frame(X = c(0, X_1, X_1 + half_swath, X_2 - half_swath, X_2, X_2 + half_swath, X_3 - half_swath, X_3, X_3 + half_swath),
                      Y = c(0, input$alt, 0, 0, input$alt, 0, 0, input$alt, 0),
                      group = c(1, 1, 1, 2, 2, 2, 3, 3, 3), facet = "proposed")
    
    tri_canopy <- data.frame(X = c(X_1 - half_swath_canopy, X_1, X_1 + half_swath_canopy, X_2 - half_swath_canopy, X_2, X_2 + half_swath_canopy, X_3 - half_swath_canopy, X_3, X_3 + half_swath_canopy),
                             Y = c(input$canopy_max, input$alt, input$canopy_max, input$canopy_max, input$alt, input$canopy_max, input$canopy_max, input$alt, input$canopy_max),
                             group = c(1, 1, 1, 2, 2, 2, 3, 3, 3), facet = "canopy")
    
    tri_target <- data.frame(X = c(X_1 - half_swath_target, X_1, X_1 + half_swath_target, X_2 - half_swath_target, X_2, X_2 + half_swath_target, X_3 - half_swath_target, X_3, X_3 + half_swath_target),
                             Y = c(0, input$alt, 0, 0, input$alt, 0, 0, input$alt, 0),
                             group = c(1, 1, 1, 2, 2, 2, 3, 3, 3), facet = "target")
    
    tri_target_canopy <- data.frame(X = c(X_1 - half_swath_target_canopy, X_1, X_1 + half_swath_target_canopy, X_2 - half_swath_target_canopy, X_2, X_2 + half_swath_target_canopy, X_3 - half_swath_target_canopy, X_3, X_3 + half_swath_target_canopy),
                                    Y = c(input$canopy_max, input$alt, input$canopy_max, input$canopy_max, input$alt, input$canopy_max, input$canopy_max, input$alt, input$canopy_max),
                                    group = c(1, 1, 1, 2, 2, 2, 3, 3, 3), facet = "target_canopy")
    
    plot_df <- bind_rows(tri, tri_canopy, tri_target, tri_target_canopy)
    
    # --- Square panels: shared x/y span, buffer split equally left/right ---
    x_range  <- range(plot_df$X)
    x_center <- mean(x_range)
    
    # Vertical layout, as fractions of the panel span (tweak these to taste):
    #   margin_frac = margin between the annotations and the panel's LEFT and TOP edges (identical)
    #   block_frac  = height taken by the three stacked annotation labels
    #   gap_frac    = space between the distance label and the annotation block
    margin_frac <- 0.02
    block_frac  <- 0.21
    gap_frac    <- 0.09
    apex_top    <- input$alt * 1.05            # error bar height; distance label sits just above
    
    span_y <- apex_top / (1 - gap_frac - block_frac - margin_frac)
    span_x <- diff(x_range) * 1.2              # 20% buffer horizontally
    span   <- max(span_x, span_y)              # one span for both axes => square panels
    
    xlim <- c(x_center - span / 2, x_center + span / 2)
    
    list(
      plot_df = plot_df,
      dim_max = span,
      xlim = xlim,
      ylim = c(0, span),
      x_lab = xlim[1] + margin_frac * span,    # left margin
      y_annot = span * (1 - margin_frac),      # top of the annotation block (same margin)
      lab_df = data.frame(alt = rep(input$alt, 4),
                          FOV = c(input$FOV, input$FOV, input$FOV_target, input$FOV_target),
                          overlap_ground = c(overlap_prop, overlap_prop, overlap_target, overlap_target),
                          overlap_canopy = c(overlap_canopy, overlap_canopy, overlap_target_canopy, overlap_target_canopy),
                          facet = c("proposed", "canopy", "target", "target_canopy"),
                          X_1 = rep(X_1, 4),
                          X_2 = rep(X_2, 4)) %>%
        mutate(X = X_2 - ((X_2 - X_1) / 2),
               alt_lab = paste0("altitude = ", input$alt, " m"),
               FOV_lab = paste0("FOV = ", FOV, "\u00b0"),
               overlap_lab_canopy = if_else(facet %in% c("canopy", "target_canopy"),
                                            paste0("top-of-canopy overlap = ", round(overlap_canopy * 100), "%"),
                                            paste0("ground overlap = ", round(overlap_ground * 100), "%")),
               overlap_color = if_else(facet %in% c("canopy", "target_canopy") & overlap_canopy > 0 |
                                         facet == "proposed" & overlap_ground >= .5 |
                                         facet == "target" & overlap_ground >= 0,
                                       "black", "red3"),
               distance_lab = paste0(round(X_2 - X_1), " m"))
    )
  })
  
  # Shared plot-building function so the on-screen render and the
  # downloaded PNG always stay in sync
  build_plot <- function(data_list) {
    ggplot() +
      geom_polygon(data = data_list$plot_df, aes(x = X, y = Y, group = group, color = factor(group), fill = factor(group)), alpha = .5) +
      geom_errorbar(data = data_list$lab_df, aes(xmin = X_1, xmax = X_2, y = input$alt * 1.05), width = input$alt * .03) +
      theme_bw(base_size = 13) +
      theme(legend.position = "none", panel.grid.major = element_blank(), panel.grid.minor = element_blank(), strip.background = element_rect(fill = "gray96")) +
      labs(x = "Distance along the ground (m)", y = "Altitude above the ground (m)", title = input$name) +
      scale_fill_manual(values = c("steelblue", "indianred", "steelblue")) +
      scale_color_manual(values = c("steelblue", "indianred", "steelblue")) +
      ggnewscale::new_scale_color() +
      geom_text(data = data_list$lab_df, aes(x = X, y = input$alt * 1.05, label = distance_lab), fontface = "bold", vjust = -1, size = 4) +
      # Annotations hang down from y_annot (altitude on top, then FOV, then overlap)
      geom_label(data = data_list$lab_df, aes(label = overlap_lab_canopy, x = data_list$x_lab, y = data_list$y_annot, color = overlap_color), vjust = 4, hjust = 0, size = 4) +
      geom_label(data = data_list$lab_df, aes(label = FOV_lab, x = data_list$x_lab, y = data_list$y_annot), vjust = 2.5, hjust = 0, size = 4) +
      geom_label(data = data_list$lab_df, aes(label = alt_lab, x = data_list$x_lab, y = data_list$y_annot), vjust = 1, hjust = 0, size = 4) +
      geom_hline(yintercept = input$canopy_max, linetype = 2) +
      scale_color_identity() +
      coord_fixed(ratio = 1, xlim = data_list$xlim, ylim = data_list$ylim, expand = FALSE) +
      facet_wrap(vars(factor(facet, levels = c("proposed", "canopy", "target", "target_canopy"),
                             labels = c("Proposed parameters", "Equivalent top-of-canopy overlap (%)",
                                        paste0("Equivalent ground overlap (%) with FOV = ", input$FOV_target, "\u00b0"),
                                        paste0("Equivalent top-of-canopy overlap (%) with FOV = ", input$FOV_target, "\u00b0")))), ncol = 2)
  }
  
  output$overlapPlot <- renderPlot({
    build_plot(plot_data())
  })
  
  output$downloadPlot <- downloadHandler(
    filename = function() {
      paste0(input$name, "_overlap_plot.png")
    },
    content = function(file) {
      p <- build_plot(plot_data())
      ggsave(file, plot = p, width = 10, height = 10, device = "png")
    }
  )
}

shinyApp(ui = ui, server = server)
