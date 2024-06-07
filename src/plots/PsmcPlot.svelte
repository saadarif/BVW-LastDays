<script>
    import { onMount } from 'svelte';
    import * as d3 from 'd3';

    export let data = [];
    export let xKey;
    export let yKey;
    export let zKey;
    export let color = "lightgrey";
    export let xScale = "log";
    export let xTicks = [];
    export let lineWidth = 2;
    export let snapTicks = false;
    export let yFormatTick = d => d;
    export let height = 650;
    export let padding = { top: 0, bottom: 15, left: 140, right: 0 };
    export let area = false;
    export let xDomain = null; // Add xDomain prop
    export let yDomain = null; // Add yDomain prop

    let chartContainer;

    onMount(() => {
        drawChart();
    });

    function drawChart() {
        const margin = { ...padding };
        const width = chartContainer.clientWidth - margin.left - margin.right;
        const chartHeight = height - margin.top - margin.bottom;

        d3.select(chartContainer).select("svg").remove();

        const svg = d3.select(chartContainer)
            .append("svg")
            .attr("width", width + margin.left + margin.right)
            .attr("height", chartHeight + margin.top + margin.bottom)
            .append("g")
            .attr("transform", `translate(${margin.left},${margin.top})`);

        // Define the x-scale
        const x = (xScale === "log" ? d3.scaleLog() : d3.scaleLinear())
            .domain(xDomain || d3.extent(data, d => d[xKey]))
            .range([0, width]);

        // Define the y-scale
        const y = d3.scaleLinear()
            .domain(yDomain || [0, d3.max(data, d => d[yKey])])
            .range([chartHeight, 0]);

        // Add the x-axis
        const xAxis = d3.axisBottom(x)
            .ticks(xTicks.length ? xTicks.length : undefined)
            .tickValues(xTicks.length ? xTicks : undefined)
            .tickFormat(d3.format(",d"));

        svg.append("g")
            .attr("transform", `translate(0,${chartHeight})`)
            .call(xAxis);

        // Add the y-axis
        const yAxis = d3.axisLeft(y)
            .tickFormat(yFormatTick);

        svg.append("g")
            .call(yAxis);

        // Define the line generator
        const line = d3.line()
            .x(d => x(d[xKey]))
            .y(d => y(d[yKey]));

        // Group data by species
        const nestedData = d3.groups(data, d => d[zKey]);

        // Color scale: give me a specie name, I return a color
        const colorScale = d3.scaleOrdinal()
            .domain([...new Set(data.map(d => d[zKey]))])
            .range(d3.schemeCategory10);

        // Draw the lines for each species
        nestedData.forEach(([species, values]) => {
            svg.append("path")
                .datum(values)
                .attr("fill", "none")
                .attr("stroke", colorScale(species))
                .attr("stroke-width", lineWidth)
                .attr("d", line);
        });
    }
</script>

<style>
    .chart-sml {
        display: flex;
        justify-content: center;
        align-items: center;
    }
</style>

<div class="chart-sml" bind:this={chartContainer}></div>