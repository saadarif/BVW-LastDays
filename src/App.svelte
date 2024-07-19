<script>
	// CORE IMPORTS
	import { setContext, onMount } from "svelte";
	import { getMotion } from "./utils.js";
	import { themes } from "./config.js";
	import Footer from "./layout/Footer.svelte";
	import Header from "./layout/Header.svelte";
	import Section from "./layout/BISection.svelte";
	//import BISection from "./layout/BISection.svelte";
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
	
	//import PsmcPlot from "./plots/PsmcPlot.svelte";
	// DEMO-SPECIFIC IMPORTS
	import bbox from "@turf/bbox";
	import { getData, setColors, getTopo, getBreaks, getColor } from "./utils.js";
	import { colors, units } from "./config.js";
	import { ScatterChart, LineChart, ColumnChart } from '@onsvisual/svelte-charts';
	import { Map, MapSource, MapLayer, MapTooltip } from "@onsvisual/svelte-maps";
  import Area from "@onsvisual/svelte-charts/src/charts/shared/Area.svelte";
	import AnnotationsData from "@onsvisual/svelte-charts/src/charts/shared/AnnotationsData.svelte";
  import { linear } from "svelte/easing";
  import { claim_svg_element, select_options } from "svelte/internal";



	// CORE CONFIG (COLOUR THEMES)
	// Set theme globally (options are 'light', 'dark' or 'lightblue')
	let theme = "light";
	setContext("theme", theme);
	setColors(themes, theme);

	const mapcolors = {
		seq5: ['rgba(234, 236, 177,0)', 'rgb(169, 216, 145)', 'rgb(0, 167, 186)', 'rgb(0, 78, 166)', 'rgb(0, 13, 84)'],
		div10: ['#67001f','#b2182b','#d6604d','#f4a582','#fddbc7','#d1e5f0','#92c5de','#4393c3','#2166ac','#053061']	
	};

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

		// Data
	let data ={psmc: {}, froh: {}, occ:{}, snpEff: {}};
	let geojson;
	//Map constants

	const occData = "./data/data_occ.csv";
  const occDataBounds = {
	  url: "./data/topo_lad.json",
	  layer: "lad",
	  code: "LAD13CD"
	};
	
	const mapbounds = {
		uk: [
			[-7, 49 ],
			[ 2, 58 ]
		],
		southernUk: [
			[-7, 49 ],
			[ 2, 53 ]
		],
	};

  const mapstyle = "https://bothness.github.io/ons-basemaps/data/style-omt.json";
	// Bindings
	let map

	// State
	let select = true;
	let showColors = true;
	let showAnnotation = false;
	let hovered; // Hovered component (chart or map)
	let selected; // Selected component (chart or map)
	let highlighted;
	let mapHighlighted = []; // Highlighted district (map only)
	let xKey = "year"; // xKey for scatter chart
	let yKey = "Ne"; // yKey for scatter chart
	let zKey = "species"; // zKey (color) for scatter chart
	let mapKey = "Count"; // Key for data to be displayed on map
	let snpchartkey = "totCounts"; //key for plotting variants

	//Chart Annotations
	let psmcAnnotations = [
    {
      text: 'End of last glacial period...',
      [xKey]: '40000',
      [yKey]: 60,
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

	// Column/barchart options
	let small = true;

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
			let feature = geojson.features.find(d => d.properties.LAD13CD == id);
			let bounds = bbox(feature.geometry);
			fitBounds(bounds);
		}
	}


	// Actions for Scroller components
	const actions = {
		map: { // Actions for <Scroller/> with id="map"
			map01: () => { // Action for <section/> with data-id="map01"
				fitBounds(mapbounds.uk);
				//mapKey = "Count"; This is the pre-1925 count
				mapHighlighted = [];
			},
			map02: () => {
				fitBounds(mapbounds.southernUk);
				//mapKey = "Count"; This is the pre-1925 count
				mapHighlighted = [];
			},
			map03: () => {
				let hl = [...data.occ].find(d => d.LAD13CD == "E07000106") //last known location of A. crategie before extirpation - Herne Bay, Canterbury
				//let hl = [...data.district.indicators].sort((a, b) => b.age_med - a.age_med)[0];
				fitById(hl.LAD13CD);
				//mapKey = "Count"; This is the pre-1925 count
				mapHighlighted = [hl.code];
			},
			map04: () => {
				fitBounds(mapbounds.uk); //return to base
				mapHighlighted = [];
			}
		},
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
		}, 
		froh_chart:{
			frohchart01: () => {
				small = true;
			},
			frohchart02: () => {
				small = false;
			},
		},
		snp_chart:{
			snpchart01: () => {
				//displays total variants
			},
			snpchart02: () => {
				snpchartkey = "homCounts";
			},
		},
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
	//PSMC
	getData(`./data/data_psmc.csv`)
		.then(arr => {
			let Netimes = arr.map((d,i) => ({
			species: d.ID,
			year: parseFloat(d.Time),
			Ne: parseFloat(d.Ne)
		}));
		data.psmc.Netimes = Netimes;
		//console.log(data.psmc.Netimes)
		});

	//FROH
	getData(`./data/data_froh.csv`)
		.then(arr => {
			let res = arr.map((d,i) => ({
			pop: d.ID,
			sample: d.sample,
			interval: d.Interval,
			freq: parseFloat(d.freq)
		}));
		data.froh.froh = res;
		//console.log(data.froh)
		});

	//SnpEff data
	getData(`./data/data_snpEff.csv`)
		.then(arr => {
			let res = arr.map((d,i) => ({
			pop: d.ID,
			sample: d.sample,
			homozygous: d.Hom_Pred,
			homCounts: parseInt(d.HomCounts),
			total: d.Tot_Pred,		
			totCounts: parseInt(d.TotCounts),
		}));
		data.snpEff.snpEff = res;
		// console.log(data.snpEff.snpEff)
		});
	
	// Get geometry for geojson maps
	getTopo(occDataBounds.url, occDataBounds.layer)
	.then(res => geojson = res);
	// Get data for geojson maps
	getData(occData)
	.then(res => {
		let vals = res.map(d => d.Count).sort((a, b) => a - b);
		let len = vals.length;
		let breaks = [
			0,0,1,5,10,80 //manual implementation of breaks
			// vals[0],
			// vals[Math.floor(len * 0.2)],
			// vals[Math.floor(len * 0.4)],
			// vals[Math.floor(len * 0.6)],
			// vals[Math.floor(len * 0.8)],
			// vals[len - 1]
		];
		res.forEach(d => {
			d.color = getColor(d.Count, breaks, mapcolors.seq5);
		});
		data.occ = res;
		//console.log(data.occ); 
	});
		
	
</script>

<!-- <OrientationPrompt /> -->


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

<Section></Section>

{#if geojson && data.occ}
<Scroller {threshold} bind:id={id['map']}>
	<div slot="background">
		<figure>
			<div class="col-full height-full">
		<Map id="map" style={mapstyle} location={{bounds: mapbounds.uk}} bind:map={map} interactive={false}>
			<MapSource
				id="lad"
				type="geojson"
				data={geojson}
				promoteId="LAD13CD"
				maxzoom={13}>
				<MapLayer
					id="lad-fill"
					idKey="LAD13CD"
					data={data.occ}
					type="fill"
					hover {hovered} on:hover={doHover}
					highlight highlighted={mapHighlighted}
					select {selected} on:select={doSelect}
					paint={{
						'fill-color': ['case',
							['!=', ['feature-state', 'color'], null], ['feature-state', 'color'],
							'rgba(255, 255, 255, 0)'
						],
						'fill-opacity': 0.6
					}}>
				<MapTooltip content={
					hovered ? `${data.occ.find(d => d.LAD13CD == hovered)["LAD13NM"].toLocaleString()}<br/></strong>${data.occ.find(d => d.LAD13CD == hovered)[mapKey].toLocaleString()}</strong>` : ''
				} />
				</MapLayer>
			</MapSource>
		</Map>
	</div>
</figure>
</div>

<div slot="foreground">
	<section data-id="map01">
		<div class="col-medium">
			<p>
				This map shows <strong>occurence</strong> of the Black-veined white, <strong>prior</strong> to its extirpation in <strong>1925</strong> by 
				district. The map shows <strong>recordings</strong> of the butterfly, from <Em color={mapcolors.seq5[1]}>least</Em> to 
				<Em color={mapcolors.seq5[4]}>most</Em>. You can hover to see the district name and density. </p>
				<p>
				<small>Source: GBIF.org (18 July 2024) GBIF 
				Occurrence Download https://doi.org/10.15468/dl.w475z3</small>
				</p>
		</div>
	</section>
	<section data-id="map02">
		<div class="col-medium">
			<p>
				This data comes from information on preserved museum specimens (some as old as<strong>1738!</strong>) and occaisional human recordings of the butterfly and is 
				incomplete and suffers from bias in recording. However, the map does show that the Black-veined white could be found in southern England 
				and eastern Wales.
			</p>
		</div>
	</section>
	<section data-id="map03">
		<div class="col-medium">
			<!-- This zooms into Centerrbury, Herne Bay was the location of the last collected specimen of A.craetgi -->
			<p>
				 The last known recording of a Black-veined white, before its extirpation, came from <strong>Herne Bay</strong>, in the 
				 north of <strong>Canterbury</strong>. 
			</p>	
		</div>
	</section>	<section data-id="map04">
		<div class="col-medium">
			<p>
				Since its extirpation there have been occaisional sightings of the butterfly
				in Britian but all are thought to be from unplanned introduction (see <a href="https://www.bbc.co.uk/news/uk-65804939">here</a> 
				for a recent case) and none have persisted.
			</p>	
		</div>
	</section>

	</div>
</Scroller>
{/if}

<Divider />

<Section>
	<h2>Reconstructing the history of a Butterfly population</h2>
</Section>

<Divider/>


{#if data.psmc.Netimes}
<Scroller {threshold} bind:id={id['chart']} splitscreen={true}>
	<div slot="background">
		<figure>
			<div class="col-wide height-full">
					<div class="chart">
						<LineChart
							height="calc(100vh - 150px)"
							data={data.psmc.Netimes} 
							title="Demographic history"
							xKey="year" yKey="Ne" zKey="species" 
							colors={showColors ? ['lightgrey'] : ['#003f5c', '#ffa600']}
							legend={showColors ? false : true}
							lineWidth={5}  yScale="log"
							area={false} 
							xScale= "log"
							xSuffix= "  years ago"
							xTicks={[10000, 50000, 100000, 250000]}  xFormatTick={d => d.toLocaleString()}
							yFormatTick={d => d.toLocaleString()}
							{highlighted} colorHighlight="#999" 
							hover {hovered} on:hover={doHover} colorHover='pink' 
							annotations={psmcAnnotations}
							labels labelKey="species"
							{animation} />
					</div>
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
{/if}

<Section>Inbreeding</Section>

{#if data.froh.froh} 
<Scroller {threshold} bind:id={id['froh_chart']} splitscreen={true}>
	<div slot="background">
		<figure>
			<div class="col-wide height-full">
					<div class="chart">
					<ColumnChart
							height="calc(100vh - 150px)"
							data={small ? data.froh.froh.filter(d => d.interval == "Small") : data.froh.froh.filter(d => d.interval == "Big") }
							xKey="pop" yKey="freq" zKey="pop"
							colors={['#003f5c', '#ffa600']}
							title="Inbreeding levels"
							mode="barcode"
							hover {hovered} on:hover={doHover} colorHover='pink' 
							{select} {selected} on:select={doSelect}
							{animation}>
							<!-- <div slot="options" class="controls small">
								{#each barchart1.options as option}
									<label><input type="radio" bind:group={barchart1.selected} value={option}/> {option}</label>
								{/each}
							</div> -->
						</ColumnChart>
					</div>
				</div>
			</figure>
		</div>
		<div slot="foreground">
			<section data-id="frohchart01">
				<div class="col-medium">
					<p>
						This plot shows the <strong>effective population size </strong> (y-axis) over <strong>time</strong> in years (x-axis). 
						Small values on the x-axis represent time <strong>closer to the present</strong>! Higher values on the x-axis represent 
						higher <strong>genetic diversity</strong> and thus, higher<strong>population size</strong>
					</p>
				</div>
			</section>
			<section data-id="frohchart02">
				<div class="col-medium">
					<p>
					
					</p>
				</div>
			</section>
			</div>
</Scroller>			
{/if}


<Section>
	<h2>Impact of variants</h2>
</Section>

{#if data.snpEff.snpEff} 
<Scroller {threshold} bind:id={id['snp_chart']} splitscreen={true}>
	<div slot="background">
		<figure>
			<div class="col-wide height-full">
					<div class="chart">
					<ColumnChart
							height="calc(100vh - 150px)"
							data={data.snpEff.snpEff}
							xKey="homozygous" yKey={snpchartkey} zKey="pop"
							colors={['#003f5c', '#ffa600']}
							title="Variants"
							mode="grouped"
							hover {hovered} on:hover={doHover} colorHover='pink' 
							{select} {selected} on:select={doSelect}
							{animation}>
							<!-- <div slot="options" class="controls small">
								{#each barchart1.options as option}
									<label><input type="radio" bind:group={barchart1.selected} value={option}/> {option}</label>
								{/each}
							</div> -->
						</ColumnChart>
					</div>
				</div>
			</figure>
		</div>
		<div slot="foreground">
			<section data-id="snpchart01">
				<div class="col-medium">
					<p>
				
					</p>
				</div>
			</section>
			<section data-id="snpchart02">
				<div class="col-medium">
					<p>
					</p>
				</div>
			</section>
			</div>
	</Scroller>			
	{/if}


<Section>
	<h2>What next?</h2>
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
