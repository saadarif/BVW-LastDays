<script>
	// CORE IMPORTS
	import { setContext, onMount } from "svelte";
	import { getMotion } from "./utils.js";
	import { themes } from "./config.js";
	import ONSHeader from "./layout/ONSHeader.svelte";
	import ONSFooter from "./layout/ONSFooter.svelte";
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
	
	import PsmcPlot from "./plots/PsmcPlot.svelte";
	// DEMO-SPECIFIC IMPORTS
	import bbox from "@turf/bbox";
	import { getData, setColors, getTopo, getBreaks, getColor } from "./utils.js";
	import { colors, units } from "./config.js";
	import { ScatterChart, LineChart, BarChart } from "@onsvisual/svelte-charts";
	import { Map, MapSource, MapLayer, MapTooltip } from "@onsvisual/svelte-maps";
  	import Area from "@onsvisual/svelte-charts/src/charts/shared/Area.svelte";
  	import { linear } from "svelte/easing";
  import { claim_svg_element } from "svelte/internal";

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
	const psmcDataSets= ["psmc"];
	const datasets = ["region", "district"];
	const topojson = "./data/geo_lad2021.json";
	const mapstyle = "https://bothness.github.io/ons-basemaps/data/style-omt.json";
	const mapbounds = {
		uk: [
			[-9, 49 ],
			[ 2, 61 ]
		]
	};

	// Data
	let data1 ={psmc: {}};
	let data = {district: {}, region: {}};
	let metadata = {district: {}, region: {}};
	let geojson;

	// Element bindings
	let map = null; // Bound to mapbox 'map' instance once initialised


	// State
	let hover = true;
	let select = true;
	let hovered; // Hovered district (chart or map)
	let selected; // Selected district (chart or map)
	$: region = selected && metadata.district.lookup ? metadata.district.lookup[selected].parent : null; // Gets region code for 'selected'
	$: chartHighlighted = metadata.district.array && region ? metadata.district.array.filter(d => d.parent == region).map(d => d.code) : []; // Array of district codes in 'region'
	let mapHighlighted = []; // Highlighted district (map only)
	let xKey = "area"; // xKey for scatter chart
	let yKey = null; // yKey for scatter chart
	let zKey = null; // zKey (color) for scatter chart
	let rKey = null; // rKey (radius) for scatter chart
	let mapKey = "density"; // Key for data to be displayed on map
	let explore = false; // Allows chart/map interactivity to be toggled on/off


	// FUNCTIONS (INCL. SCROLLER ACTIONS)

	// Functions for chart and map on:select and on:hover events
	function doSelect(e) {
		console.log(e);
		selected = e.detail.id;
		if (e.detail.feature) fitById(selected); // Fit map if select event comes from map
	}
	function doHover(e) {
		hovered = e.detail.id;
	}

	// Functions for map component
	function fitBounds(bounds) {
		if (map) {
			map.fitBounds(bounds, {animate: animation, padding: 30});
		}
	}
	function fitById(id) {
		if (geojson && id) {
			let feature = geojson.features.find(d => d.properties.AREACD == id);
			let bounds = bbox(feature.geometry);
			fitBounds(bounds);
		}
	}

	// Actions for Scroller components
	const actions = {
		map: { // Actions for <Scroller/> with id="map"
			map01: () => { // Action for <section/> with data-id="map01"
				fitBounds(mapbounds.uk);
				mapKey = "density";
				mapHighlighted = [];
				explore = false;
			},
			map02: () => {
				fitBounds(mapbounds.uk);
				mapKey = "age_med";
				mapHighlighted = [];
				explore = false;
			},
			map03: () => {
				let hl = [...data.district.indicators].sort((a, b) => b.age_med - a.age_med)[0];
				fitById(hl.code);
				mapKey = "age_med";
				mapHighlighted = [hl.code];
				explore = false;
			},
			map04: () => {
				fitBounds(mapbounds.uk);
				mapKey = "age_med";
				mapHighlighted = [];
				explore = true;
			}
		},
		chart: {
			chart01: () => {
				xKey = "area";
				yKey = null;
				zKey = null;
				rKey = null;
				explore = false;
			},
			chart02: () => {
				xKey = "area";
				yKey = null;
				zKey = null;
				rKey = "pop";
				explore = false;
			},
			chart03: () => {
				xKey = "area";
				yKey = "density";
				zKey = null;
				rKey = "pop";
				explore = false;
			},
			chart04: () => {
				xKey = "area";
				yKey = "density";
				zKey = "parent_name";
				rKey = "pop";
				explore = false;
			},
			chart05: () => {
				xKey = "area";
				yKey = "density";
				zKey = null;
				rKey = "pop";
				explore = true;
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
	psmcDataSets.forEach(demo => {
		getData(`./data/data_${demo}.csv`)
		.then(arr => {
			let Netimes = arr.map((d,i) => ({
			species: d.ID,
			year: parseFloat(d.Time),
			Ne: parseFloat(d.Ne)
		}));
		data1[demo].Netimes = Netimes;
		console.log(data1.psmc.Netimes)
		});
	});
	

	
	datasets.forEach(geo => {
		getData(`./data/data_${geo}.csv`)
		.then(arr => {
			let meta = arr.map(d => ({
				code: d.code,
				name: d.name,
				parent: d.parent ? d.parent : null
			}));
			let lookup = {};
			meta.forEach(d => {
				lookup[d.code] = d;
			});
			metadata[geo].array = meta;
			metadata[geo].lookup = lookup;

			let indicators = arr.map((d, i) => ({
				...meta[i],
				area: d.area,
				pop: d['2020'],
				density: d.density,
				age_med: d.age_med
			}));

			if (geo == "district") {
				['density', 'age_med'].forEach(key => {
					let values = indicators.map(d => d[key]).sort((a, b) => a - b);
					let breaks = getBreaks(values);
					indicators.forEach((d, i) => indicators[i][key + '_color'] = getColor(d[key], breaks, colors.seq));
				});
			}
			data[geo].indicators = indicators;

			let years = [
				2001, 2002, 2003, 2004, 2005,
				2006, 2007, 2008, 2009, 2010,
				2011, 2012, 2013, 2014, 2015,
				2016, 2017, 2018, 2019, 2020
			];

			let timeseries = [];
			arr.forEach(d => {
				years.forEach(year => {
					timeseries.push({
						code: d.code,
						name: d.name,
						value: d[year],
						year
					});
				});
			});
			data[geo].timeseries = timeseries;
		});
	});

	getTopo(topojson, 'geog')
	.then(geo => {
		geo.features.sort((a, b) => a.properties.AREANM.localeCompare(b.properties.AREANM));
		geojson = geo;
	});
</script>

<OrientationPrompt />

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


<BISection>
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
</BISection>	

<Divider/>

<Filler bgimage="./img/BVW_museum1.png"	theme="lightblue" short={true} wide={true} center={false}/>

<Divider/>

{#if data1.psmc.Netimes}
	<Media
		col="medium"
		caption="Source: Paper "
	>
	<div class="chart-sml">
	<LineChart
	data={data1.psmc.Netimes}
	xKey="year"
	yKey="Ne"
	zKey="species"
	xScale="log"
	xTicks={[0, 10000, 50000, 100000, 150000]} 
	xSuffix= ""
	lineWidth={5}
	yFormatTick={d => d}  ySuffix=" "
	height={600}
	
	colors={['#003f5c', '#ffa600']}
	colorHover='#bc5090'
	area={false} 
	{hover} labels legend 
	snapTicks={false}/>
	</div>
	</Media>
{/if}

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

<ONSFooter />

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
