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

ui <- fluidPage(
  titlePanel("Flightline Overlap Visualization"),

  sidebarLayout(
    sidebarPanel(
      textInput("name", "Site Name:", "Kisangani"),
      numericInput("alt", "Altitude (m):", 700),
      sliderInput("overlap", "Overlap (%):", min = 0, max = 1, value = .5, step = .05),
      sliderInput("FOV", "Sensor FOV (deg):", min = 0, max = 180, value = 40, step = 1),
      sliderInput("FOV_target", "Target FOV (deg):", min = 0, max = 180, value = 30, step = 1),
      numericInput("canopy_max", "Max Canopy Height (m):", 40),
      downloadButton("downloadPlot", "Download Plot")

    ),

    mainPanel(
      plotOutput("overlapPlot", height = "800px")
    )
  )
)

server <- function(input, output) {

  # Reactive calculations to update when inputs change
  plot_data <- reactive({

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
    overlap_distance <- half_swath * 2 * input$overlap
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

    list(
      plot_df = bind_rows(tri, tri_canopy, tri_target, tri_target_canopy),
      dim_max = max(input$alt, (X_3 + half_swath), (X_3 + half_swath_target)) * 1.2,
      lab_df = data.frame(alt = rep(input$alt, 4),
                          FOV = c(input$FOV, input$FOV, input$FOV_target, input$FOV_target),
                          overlap_ground = c(input$overlap, input$overlap, overlap_target, overlap_target),
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
      theme_bw(base_size = 12) +
      theme(legend.position = "none", panel.grid.major = element_blank(), panel.grid.minor = element_blank(), strip.background = element_rect(fill = "gray96")) +
      labs(x = "distance along the ground (m)", y = "altitude above the ground (m)", title = input$name) +
      scale_fill_manual(values = c("steelblue", "indianred", "steelblue")) +
      scale_color_manual(values = c("steelblue", "indianred", "steelblue")) +
      ggnewscale::new_scale_color() +
      geom_text(data = data_list$lab_df, aes(x = X, y = input$alt * 1.05, label = distance_lab), fontface = "bold", vjust = -1, size = 3.5) +
      geom_label(data = data_list$lab_df, aes(label = overlap_lab_canopy, x = 0, y = data_list$dim_max, color = overlap_color), vjust = 4, hjust = 0, size = 3.5) +
      geom_label(data = data_list$lab_df, aes(label = FOV_lab, x = 0, y = data_list$dim_max), vjust = 2.5, hjust = 0, size = 3.5) +
      geom_label(data = data_list$lab_df, aes(label = alt_lab, x = 0, y = data_list$dim_max), vjust = 1, hjust = 0, size = 3.5) +
      geom_hline(yintercept = input$canopy_max, linetype = 2) +
      scale_color_identity() +
      coord_fixed(ratio = 1) +
      expand_limits(y = c(0, data_list$dim_max)) +
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
      ggsave(file, plot = p, width = 15, height = 15, device = "png")
    }
  )
}

shinyApp(ui = ui, server = server)
