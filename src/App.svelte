<script>
	// CORE IMPORTS
	import { setContext, onMount } from "svelte";
	import { getMotion } from "./utils.js";
	import { themes } from "./config.js";
	import OBUHeader from "./layout/OBUHeader.svelte";
	import Footer from "./layout/Footer.svelte";
	import Header from "./layout/Header.svelte";
	import Section from "./layout/BISection.svelte";
	import BISection from "./layout/BISection.svelte";
	import Media from "./layout/Media.svelte";
	import Scroller from "./layout/Scroller.svelte";
	import Filler from "./layout/Filler.svelte";
	import Divider from "./layout/Divider.svelte";
	import Toggle from "./ui/Toggle.svelte";
	import Arrow from "./ui/Arrow.svelte";
	import Em from "./ui/Em.svelte";

	import OrientationPrompt from './ui/OrientationPrompt.svelte';	
	//import StepLinePlot from "./plots/StepLinePlot.svelte";
	//import * as d3 from 'd3';
	
	import PsmcPlot from "./plots/PsmcPlot.svelte";
	// DEMO-SPECIFIC IMPORTS
	import bbox from "@turf/bbox";
	import { getData, setColors, getTopo, getBreaks, getColor } from "./utils.js";
	import { colors, units } from "./config.js";
	import { ScatterChart, LineChart, BarChart } from '@onsvisual/svelte-charts';
	import { Map, MapSource, MapLayer, MapTooltip } from "@onsvisual/svelte-maps";
  	import Area from "@onsvisual/svelte-charts/src/charts/shared/Area.svelte";
	import AnnotationsData from "@onsvisual/svelte-charts/src/charts/shared/AnnotationsData.svelte";
  	import { linear } from "svelte/easing";
  	import { claim_svg_element } from "svelte/internal";
  import Annotations from "@onsvisual/svelte-charts/src/charts/shared/Annotations.svelte";


	// CORE CONFIG (COLOUR THEMES)
	// Set theme globally (options are 'light', 'dark' or 'lightblue')
	let theme = "light";
	setContext("theme", theme);
	setColors(themes, theme);

	// CONFIG FOR SCROLLER COMPONENTS
	// Config
	const threshold = 0.65;
	// State
	let animation = getMotion(); // Set animation preference depending on browser preference
	let id = {}; // Object to hold visible section IDs of Scroller components
	let idPrev = {}; // Object to keep track of previous IDs, to compare for changes
	onMount(() => {
		idPrev = {...id};
	});

	// DEMO-SPECIFIC CONFIG
	// Constants
	const DataSets= ["psmc"];
	

	// Data
	let data ={psmc: {}};
	

	// State
	let select = true;
	let showColors = true;
	let showAnnotation = false;
	let hovered; // Hovered district (chart or map)
	let selected; // Selected district (chart or map)
	let highlighted;
	let mapHighlighted = []; // Highlighted district (map only)
	let xKey = "year"; // xKey for scatter chart
	let yKey = "Ne"; // yKey for scatter chart
	let zKey = "species"; // zKey (color) for scatter chart

	//annotation test
	//let annotations = [{top: '15px', bottom: '100px', left: '100px', right: '25px', text: "hello!"}]
    //testing annotations Data
	let psmcAnnotations = [
    {
      text: 'End of last glacial period...',
      [xKey]: '60000',
      [yKey]: 80,
      dx: 15, // Optional pixel values
      dy: -5,
      arrows: [{
        clockwise: false, // true or false, defaults to true
        source: {
          anchor: 'left-middle',
          dy: 5,
          dx: -40
        },
        target: {
           // These can be expressed in our data units if passed under the data keys
		  [xKey]: '20000',
          [yKey]: 22,
          // Optional adjustments
          dx: 2,
          dy: 5
        }
      },     
   ]}
];
    

	// Functions for chart and map on:select and on:hover events
	function doSelect(e) {
		console.log(e);
		selected = e.detail.id;
		if (e.detail.feature) fitById(selected); // Fit map if select event comes from map
	}
	function doHover(e) {
		console.log(e.detail.id)
		hovered = e.detail.id;
	}
	
	// Actions for Scroller components
	const actions = {
		chart: {
			chart01: () => {
				highlighted = [];
				showColors = true;
			
			},
			chart02: () => {
				highlighted = ["France"]
				showColors = true;
				showAnnotation = true;
				
			},
			chart03: () => {
				highlighted= ["Britain"]
				showColors = true;
				showAnnotation = true;
				
			},
			chart04: () => {
				highlighted = [];
				showColors = false;
				showAnnotation = true;
				
			}
		}
		
	};
	// Code to run Scroller actions when new caption IDs come into view
	function runActions(codes = []) {
		codes.forEach(code => {
			if (id[code] != idPrev[code]) {
				if (actions[code][id[code]]) {
					actions[code][id[code]]();
				}
				idPrev[code] = id[code];
			}
		});
	}
	$: id && runActions(Object.keys(actions)); // Run above code when 'id' object changes


	//INITIALISATION CODE
	//Read in the Datasets
	DataSets.forEach(demo => {
		getData(`./data/data_${demo}.csv`)
		.then(arr => {
			let Netimes = arr.map((d,i) => ({
			species: d.ID,
			year: parseFloat(d.Time),
			Ne: parseFloat(d.Ne)
		}));
		data[demo].Netimes = Netimes;

		});
	});

	
	
	//loading data solution for chart.js . solution from ChatGPT
	// let datasets1 = [];
	// let labels = [];
	// let annotationBox = {
	// 	xMin: 18000,
	// 	xMax: 22000,
	// 	yMin: 0,
	// 	yMax: 250
	// };

	// // Calculate or set xMin and xMax values
	// let xMin = 10000;
 	// let xMax = 150000;
	// // List of CSV files to load
	// const psmcDataSets1 = ['data_psmc.csv'];
	// let loading = true;

	// async function loadData() {
	// 	let chartData = {};

	// 	for (let file of psmcDataSets1) {
	// 	const data = await d3.csv(`./data/${file}`);
	// 	data.forEach(d => {
	// 		const category = d.ID;
	// 		if (!chartData[category]) {
	// 		chartData[category] = [];
	// 		}
	// 		chartData[category].push({ x: +d.Time, y: +d.Ne });
	// 	});
	// 	}

	// 	// Process the data to create datasets and labels
	// 	let categories = new Set(Object.keys(chartData));
	// 	labels = Array.from(new Set(Object.values(chartData).flat().map(d => d.x)));
	// 	datasets1 = Array.from(categories).map((category, index) => ({
	// 	label: category,
	// 	data: chartData[category],
	// 	borderColor: `hsl(${index * 60}, 100%, 50%)`
	// 	}));
	// 	console.log(datasets1)
	// 	loading = false;
	// }

	// onMount(loadData);
		
	
</script>

<OrientationPrompt />

<OBUHeader filled={true}  />

<Header bgfixed={false} theme="light" center={false} short={true}>
	<h1 style="margin-top: -100px; margin-left: 0px"> The last days of the Black-veined white butterfly in Britain</h1>
	<div style="margin-top: 5px;  background-color: #fff; opacity: 0.6; z-index: -1;margin-left: 0px"><p class="text-big" >
		<strong>
			A genomic history of the the Black-veined white butterfly in Britain from its arrival to its demise in the early twentieth century
		</strong>
		</p>
	</div>
	<div style="margin-top: 60px;margin-left: 0px;">
		<Arrow color="black" {animation}><strong>Scroll to begin</strong></Arrow>
	</div>
</Header>


<Filler theme="light" short={true} wide={true} center={true}>
	<p class="text-small">
		<strong>By</strong>: Saad Arif </p>
		<p class="text-small"><strong>Cover Illustration</strong>: Lizzie Harper
	</p>
	<p class="text-small"> <strong>Based on data from:</strong></p>
	<p class="text-small">
		<small>The last days of Aporia crataegi (L.) in Britain: evaluating genomic erosion in an extirpated butterfly. (2024.)
Rebecca Whitla, Korneel Hens, James Hogan, Geoff Martin, Casper Breuker, Timothy G. Shreeve, Saad Arif
bioRxiv 2023.12.19.572305; doi: https://doi.org/10.1101/2023.12.19.572305 </small>
	</p>
</Filler>

<Divider/>


<!--<BISection>
	<div slot="image">
		<img src="./img/resized_BVW_pinned.png" alt="Left Image">
	</div>
	<div>
	<h2>A butterfly disappearance, museums and genomics</h2>
	<p>
		The Black-veined white butterfly (<em>Aporia crataegi</em>) is a large butterfly that is common and widespread in the northern hemisphere from Europe 
		to Japan. However, in some places it is in decline and has completely disappeared from the Netherlands, Czechia, and South Korea [Refs]. 
		It had been recorded in Britain as early as 1667 [REF] but went extinct in the early twentieth century. Prior to its extirpation in Britain, it could be found in southern England and Wales.
		Why did the Black-veined white disappear from Britain? Numerous hypothesis have been suggested, including a run of unsually "wet" Autumns, pathogen infection, and predation.
		Given that this butterfly disappeared from Britain in the early twentieth century, it is difficult to pinpoint the exact cause of its disappearence. Over the years, there have been various attempts
		to reintroduce this species to Britain but none have been successful thus far. 
	</p>
	<p>Museums contains large collections of butterflies, some from as early as the 18th century, collected by scientists and butterfly enthusiasts.
	   Modern advances in genomics now allow us to interrogate the genomes of these long-dead individuals. To peer into the history of the Black-veined white in Britian, we extracted DNA from musueum specimens dating from the mid-19<sup>th</sup> 
	   to the early 20<sup>th</sup> century. We applied genomic tools to build a demographic history of this species in Britain, from its arrival to its eventual demise. 
	   These result also give a snapshot of its "genomic health" around the time of its disappearance,
	   which may be useful in understanding the extinction process and aid in the conservation of extant species or populations of insects.
	</p>
	</div>
</BISection>-->

<Section>
	<h2>A butterfly disappearance, museums and genomics</h2>
	<p>
		The Black-veined white butterfly (<em>Aporia crataegi</em>) is a large butterfly that is common and widespread in the northern hemisphere from Europe 
		to Japan. However, in some places it is in decline and has completely disappeared from the Netherlands, Czechia, and South Korea [Refs]. 
		It had been recorded in Britain as early as 1667 [REF] but went extinct in the early twentieth century. Prior to its extirpation in Britain, it could be found in southern England and Wales.
		Why did the Black-veined white disappear from Britain? Numerous hypothesis have been suggested, including a run of unsually "wet" Autumns, pathogen infection, and predation.
		Given that this butterfly disappeared from Britain in the early twentieth century, it is difficult to pinpoint the exact cause of its disappearence. Over the years, there have been various attempts
		to reintroduce this species to Britain but none have been successful thus far. 
	</p>
	<p>Museums contains large collections of butterflies, some from as early as the 18th century, collected by scientists and butterfly enthusiasts.
	   Modern advances in genomics now allow us to interrogate the genomes of these long-dead individuals. To peer into the history of the Black-veined white in Britian, we extracted DNA from musueum specimens dating from the mid-19<sup>th</sup> 
	   to the early 20<sup>th</sup> century. We applied genomic tools to build a demographic history of this species in Britain, from its arrival to its eventual demise. 
	   These result also give a snapshot of its "genomic health" around the time of its disappearance,
	   which may be useful in understanding the extinction process and aid in the conservation of extant species or populations of insects.
	</p>
</Section>

<Divider/>

<Filler bgimage="./img/BVW_museum1.png"	theme="lightblue" short={true} wide={true} center={false}/>

<Section>
	<h2>Reconstructing the history of a Butterfly population</h2>
</Section>

<Divider/>

<!--{#if data.psmc.Netimes}
	<Media
		col="medium"
		caption="Source: Paper "
	>
		<div class="chart-sml">
			<LineChart
			data={data.psmc.Netimes}
			xKey="year"
			yKey="Ne"
			zKey="species"	  <slot name="front"/>

			xScale= "log"
			xTicks={[1000,10000, 50000, 100000, 500000]} 
			lineWidth={4}
			height={500}
			colors={['#003f5c', '#ffa600']}

			area={false} 
			padding={{ top: 0, bottom: 28, left: 35, right: 60 }}
			{animation} labels
			{hover} {select}
			snapTicks={false} />
		</div>
	</Media>
{/if} -->


<Scroller {threshold} bind:id={id['chart']} splitscreen={true}>
	<div slot="background">
		<figure>
			<div class="col-wide height-full">
				{#if data.psmc.Netimes}
					<div class="chart">
						<LineChart
							height="calc(100vh - 150px)"
							data={data.psmc.Netimes} 
							colors={showColors ? ['lightgrey'] : ['#003f5c', '#ffa600']}
							legend={showColors ? false : true}
							lineWidth={5}  yScale="log"
							area={false} 
							{xKey} {yKey} {zKey} 
							xScale= "log"
							xSuffix= "  years ago"
							xTicks={[1000,10000, 50000, 100000, 250000]}  xFormatTick={d => d.toLocaleString()}
							yFormatTick={d => d.toLocaleString()}
							{highlighted} colorHighlight='#999'
							hover {hovered} on:hover={doHover} colorHover='pink' 
							annotations={psmcAnnotations}
							labels labelKey="species"
							{animation} />
					</div>
				{/if}
			</div>
		</figure>
	</div>

	<div slot="foreground">
		<section data-id="chart01">
			<div class="col-medium">
				<p>
					This plot shows the <strong>effective population size </strong> (y-axis) over <strong>time</strong> in years (x-axis). 
					Small values on the x-axis represent time <strong>closer to the present</strong>! Higher values on the x-axis represent 
					higher <strong>genetic diversity</strong> and thus, higher<strong>population size</strong>
				</p>
			</div>
		</section>
		<section data-id="chart02">
			<div class="col-medium">
				<p>
					The <Em color=#999> highlighted line</Em> is the demographic reconstruction of a single individual from northwestern
					 <strong>France</strong> collected in the early 1900s. Its population size is low for most of the last 500,000 years but showing
					 a small peak at roughly 125,000 years ago, corresponding to the penultimate interglacial period (the Eemian interglacial). The population
					 then contracts up till around 12,000 years ago. This time corresponds to the end of the last glacial maximum (LGM). At this point, species of all kinds
					 expanded all over europe from their warm southern refugia and we find the signs of an exponential population increase in the genome of this 
					 Black-veined white butterfly from France. 
				</p>
			</div>
		</section>
		<section data-id="chart03">
			<div class="col-medium">
				<p>
					This <Em color=#999> highlighted line</Em> is the demographic reconstruction of a single individual from kent county in eastern
					 <strong>Great Britain</strong> collected in the 1860s. For most of its history, it follows a similar trajectory to the French butterfly, however,
					 it shows no signs of population increase but rather a population <strong>decrease </strong> at the end of the LGM.
				</p>
				<p>
					What happened? This decrease in population size at the end of the LGM is exactly what we would expect to see if butterflies began colonizing the 
					British Isles at this time. The British Isles would have been founded by a relatively small number of Black-veined white to those that lived on the mainland.
				</p>
			</div>
		</section>
		<section data-id="chart04">
			<div class="col-medium">
				<p>
					These demographic recontructions tell us two important things: <strong>(i)</strong> <Em color='#003f5c'>British</Em> Black-veined white have a 
					distinct demographic history compared to <Em color='#ffa600'>European</Em>. Hence, the British black-veined white were long
					term residents in the UK, rather than recent migrants
				<strong>(ii)</strong> Black-veined white colonizing <Em color='#003f5c'>Britain</Em>, showed reduced genetic diversity,
						 presumably as a result of colonization by a small number of indviduals
					
				</p>
			</div>
		</section>
	</div>
</Scroller>


<!--<Media col="medium" caption="Source: Paper ">
<h1>Step Line Chart</h1>
<div class="chart-sml">

{#if !loading}
	<StepLinePlot 
	datasets={datasets1}
	{labels} 
	{annotationBox}
	xMin={xMin}
	xMax={xMax}
	yMax={250} 
	borderWidth={3}/>
{/if}
</div>
</Media> -->


<Scroller {threshold} >
		<div slot="background" >
				<figure>
					<div class="col-full height-full" style='background-image: url("./img/BVW_museum1.png"); background-size: cover;'/>
				</figure>
		</div>

		<div slot="foreground">
			<section><div><p>This is one section</p></div></section>
			<section><div><p>This is a another section</p></div></section>
		</div>
</Scroller>


<Section>
	<h2>How to use this template</h2>
	<p>
		You can find the source code and documentation on how to use this template in <a href="https://github.com/ONSvisual/svelte-scrolly/" target="_blank">this Github repo</a>.
	</p>
</Section>


<Footer />

<style>
	/* Styles specific to elements within the demo */
	:global(svelte-scroller-foreground) {
		pointer-events: none !important;
	}
	:global(svelte-scroller-foreground section div) {
		pointer-events: all !important;
	}
	select {
		max-width: 350px;
	}
	.chart {
		margin-top: 45px;
		width: calc(100% - 5px);
	}
	.chart-full {
		margin: 0 20px;
	}
	.chart-sml {
		font-size: 0.85em;
	}
	/* The properties below make the media DIVs grey, for visual purposes in demo */
	.media {
		background-color: #f0f0f0;
		display: -webkit-box;
		display: -ms-flexbox;
		display: flex;
		-webkit-box-orient: vertical;
		-webkit-box-direction: normal;
		-ms-flex-flow: column;
		flex-flow: column;
		-webkit-box-pack: center;
		-ms-flex-pack: center;
		justify-content: center;
		text-align: center;
		color: #aaa;
	}
</style>
