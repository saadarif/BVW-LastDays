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
	import ObuHeader from "./layout/OBUHeader.svelte";

	import OrientationPrompt from './ui/OrientationPrompt.svelte';	
	//import StepLinePlot from "./plots/StepLinePlot.svelte";
	//import * as d3 from 'd3';
	import Comments from "disqus-svelte"; 
	
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
			[-7, 50 ],
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
	let mapKey = "Count"; // Key for data to be displayed on map
	let snpchartkey = "totCounts"; //key for plotting variants
	let rohTitle, snpTitle; //title for animated barcode plots

	//Chart Annotations
	let psmcAnnotations = [
    {
      text: 'End of last glacial period...',
      [xKey]: '30000',
      [yKey]: 50,
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
		  [xKey]: '17000',
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
				rohTitle = "Short RoHs";
			},
			frohchart02: () => {
				small = false;
				rohTitle = "Long RoHs";
			},
		},
		snp_chart:{
			snpchart01: () => {
				snpchartkey = "totCounts";
				snpTitle= "Total Genetic Load"
			},
			snpchart02: () => {
				snpchartkey = "homCounts";
				snpTitle= "Realised Genetic Load (homozygotes)"
			},
			snpchart03: () => {
				// snpchartkey = "homCounts";
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
	getData(`./data/data_psmc_shorter.csv`)
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
<!-- <ObuHeader/> -->

<Header bgfixed={false} theme="light" center={false} short={true}>
	<h1 style="margin-top: 50px; margin-left: 0px"> A genomic view of the demise of <em>Aporia crataegi</em> (L.): The Black-veined White</h1>
	<div style="margin-top: 5px; background-color: #fff; opacity: 0.6; z-index: -1;margin-left: 0px;"><p class="text-big" >
		<strong>
			A genomic history of the the Black-veined white butterfly in Britain from its arrival to its demise in the early twentieth century
		</strong>
		</p>
	</div>
	<div style="margin-top: 60px;margin-left:  0px;">
		<Arrow color="black" {animation}><strong>Scroll to begin</strong></Arrow>
	</div>
</Header>


<Filler theme="light" short={true} wide={true} center={true}>
	<p class="text-small">
		<!-- <strong>By</strong>: Saad Arif </p> -->
	
	<p class="text-small"> <strong>The following is based on data and references from:</strong></p>
	<p class="text-small">
		<small>The last days of Aporia crataegi (L.) in Britain: evaluating genomic erosion in an extirpated butterfly. (2024).
Rebecca Whitla, Korneel Hens, James Hogan, Geoff Martin, Casper Breuker, Timothy G. Shreeve, Saad Arif.
<em>Molecular Ecology</em>, e17518; doi: https://doi.org/10.1111/mec.17518 </small>
	</p>
</Filler>

<Divider/> 


<Section>
	<h2>The Black-veined white in Britain</h2>
	<p>
		The Black-veined white butterfly (<em>Aporia crataegi</em>) is a large butterfly that is common and widespread in the northern hemisphere from Europe 
		to Japan. It was once a common garden and meadow species in southern Britian, with records dating back to 1667. However, towards the middle of the nineteenth
		century the butterfly started disappearing from the western and central part of its range and eventually disappeared altogether by the first quarter
		of the twentieth century. More recently, the butterfly has also disappeared from South Korea and the Netherlands.
		<p></p>
		<img class="image" width="95%" src="./img/wiki_cp.png" alt="Black-veined whie resting on flower">
</Section>

<Divider/>


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
				<MapLayer
					  	id="lad-line"
					  	type="line"
					  	paint={{
					  		'line-color': ['case',
					  			['==', ['feature-state', 'hovered'], true], 'orange',
					  			['==', ['feature-state', 'selected'], true], 'black',
					  			['==', ['feature-state', 'highlighted'], true], 'black',
					  			'rgba(255,255,255,0)'
					  		],
					  		'line-width': 2
					  	}}
				    />
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
				This data comes from information on preserved museum specimens (some as old as <strong>1738</strong>)! and occasional human recordings of the butterfly but is 
				incomplete and suffers from bias in recording. <br/><br/> However, the map does show that the Black-veined white could be found in southern England 
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
				Since 1925 there have been occasional sightings of the butterfly
				in Britain but all are thought to be from unplanned introductions from European stock (see <a href="https://www.bbc.co.uk/news/uk-65804939">here</a> 
				for a recent case), a practise that was already common by mid to late nineteenth century. But none of the introductions have persisted.
			</p>	
		</div>
	</section>

	</div>
</Scroller>
{/if}

<Divider />

<Section>
	<h2>Why did the Black-veined White disappear?</h2>
	<p>
	No one is quite sure why the butterfly disappeared but some potential reasons have 
	been explored. The most plausible of these include: predation by small birds (which increased due to decline of raptorial birds), 
	fungal or viral disease, and a series on unseasonably wet autumns. It is quite likely a combination of these 
	and other factors contributed to the ultimate demise of the butterfly in Britain.  
	</p>
	<p>Apart from external factors such as climate, disease and other man-made perturbations, genetics can also exacerbate
		extinction risk. Although not usually the direct cause of extinction, lack of genetic diversity may put species or populations
		at risk of extinction. The role of genetics in the demise of the Black-veined white has never been explored and until recently would not have
		been possible.
	</p>
	<p>
		Due to improvements in DNA extraction, sequencing technologies and museum collections, we can now do genomics in century-old museum specimens.
		We wanted to use this technology to examine the genomics of Black-veined white before it disappeared from Britain. 
	</p>
	<p></p>
	<img class="image" width="95%" src="./img/museum.jpg" alt="Drawers of museum specimens">
	<br>
	<p>
		We conducted genomics on 100-175 year-old specimens to explore historical demography and genetic fitness in British Black-veined White butterflies. For the first time, we were able
		to sequence whole genomes from Black-veined white butterflies, caught as early as 1854, and ask the following questions:
	</p>
	<ul>
		<li>How has the population size of the Black-veined white changed since arriving in Britain?</li>
		<li>Is there any evidence of inbreeding in the 19th century just prior to its demise?</li>
		<li>Was there a decrease in the genetic fitness associated with its demise?</li>
	</ul>

		<p>In order to preserve
			as much of these museum specimens for any future work (e.g. morphology) we used only 1 or 2 legs to extract DNA. 
			We share our results below.</p>
		<p></p>
</Section>

<Filler bgimage="./img/BVW_museum1.png"	theme="lightblue" short={true} wide={true} center={false}/>

<Divider/>

<Section>
	<h2>Reconstructing the historical demography of the Black-veined white</h2>

	<p>
	The current insect fauna of Great Britain is thought to have started arriving sometime around the <a href="https://www.antarcticglaciers.org/glacial-geology/british-irish-ice-sheet/last-glacial-maximum/the-british-irish-ice-sheet-an-introduction/">
	last glacial maximum</a> or the LGM. These insects would have arrived from the continent sometime between 12-15,000 years ago. Early colonisers
	would represent a small sample of the populations found on the continent and would also harbor only a fraction of the continental
	genetic diversity, a phenomenom referred to as a <strong><a href="https://en.wikipedia.org/wiki/Population_bottleneck">genetic bottleneck</a></strong>. Over many generations, these insects may recover
	from this bottleneck due to subsequent expansion in population size or continued immigration from the continent.
	</p>

	<p><em>When did the Black-veined white arrive in Britian? Is there any evidence of a historical bottleneck and is there a subsequent recovery
		post-colonisation?</em> To answer these questions we reconstructed the historical demography from a single Black-veiend white
		collected in 1858 in Herne Bay, Kent. For comparison, we present the same analysis from an individual caught in 
		France in 1921.
	</p>

</Section>

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
							xSuffix= " years ago"
							xTicks={[10000, 25000, 50000, 100000]}  xFormatTick={d => d.toLocaleString()}
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
					Small values on the x-axis represent time <strong>closer to the present</strong>. Higher values on the y-axis represent 
					higher <strong>genetic diversity</strong> and thus, higher <strong>population size</strong>
				</p>
			</div>
		</section>
		<section data-id="chart02">
			<div class="col-medium">
				<p>
					The <Em color=#999> highlighted line</Em> is the demographic reconstruction from a single individual from
					 <strong>France</strong> collected in 1921. The population shows a gradual decline up until roughly 15,000 years ago. This time corresponds to the end of the last glacial maximum (LGM). At this point, species of all kinds
					 expanded and mixed all over europe from their warm southern refugia and we find the signs of a drastic increase in genetic diversity. 
				</p>
			</div>
		</section>
		<section data-id="chart03">
			<div class="col-medium">
				<p>
					This <Em color=#999> highlighted line</Em> is the demographic reconstruction of an individual from southeastern
					 <strong>Britain</strong> collected in 1858. For most of its history, it follows a similar trajectory to the French butterfly, however,
					 it shows no signs of population increase but rather a population <strong>decrease </strong> at the end of the LGM.
				</p>
				<p>
					This decrease in population size at the end of the LGM is exactly what we would expect to see if butterflies began colonizing the 
					British Isles at this time. The British Isles would have been founded by a relatively small number of Black-veined white from those that lived on the mainland.
					Additionally, there are no signs of recovery or increase post-colonisation, however this reconstruction offers limited resolution
					in the last 10,000 years.
				</p>
			</div>
		</section>
		<section data-id="chart04">
			<div class="col-medium">
				<p>
					These demographic recontructions tell us two important things: <br/> <strong>(i)</strong> <Em color='#003f5c'>British</Em> Black-veined white have a 
					distinct demographic history compared to <Em color='#ffa600'>European</Em>. Hence, the British black-veined white were long
					term residents in the UK, rather than recent migrants. <br/>
				<strong>(ii)</strong> Black-veined white colonizing <Em color='#003f5c'>Britain</Em>, showed reduced genetic diversity,
						 presumably as a result of colonization by a small number of indviduals
					
				</p>
			</div>
		</section>
	</div>
</Scroller>
{/if}

<Divider/>

<Section>
	<h2>Were there more recent reductions in population size?</h2>
	<p>The method from the previous section is good at reconstructing signals of past bottlenecks or expansions but is poor for more 
		recent times (last 10,000 years). Nineteenth century records suggest a spasmodic decline in Black-veined white occurence
		across Britain. Could our genomic data be used to corroborate such records?
	</p>
	<p>
		The degree of inbreeding can be more useful in determining more recent declines in a population. We measured 
		inbreeding as the proportion of the genome in homozygous state for each individual. Short streches or 
		<a href="https://en.wikipedia.org/wiki/Runs_of_homozygosity"><strong>runs of homozygosity</strong></a> (RoHs), a hundred thousand DNA bases long,
		suggest historial inbreeding, whereas long RoHs of 1 million bases or more are indicative
		of more recent inbreeding that might be expected from a shrinking gene-pool. 

	</p>
</Section>

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
							title={rohTitle}
							mode="barcode"
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
						The plot on right shows a comparison of the proportion of the genome in <strong>short</strong> RoHs, on the vertical axis, between genomes of museums sample of
						 <Em color='#003f5c'>British</Em> and <Em color='#ffa600'>European</Em> origin. Prior to their extinction, <Em color='#003f5c'>British</Em> Black-veined
						 white had consistently larger proportions of their genome in RoH. However, this pattern only corroborates ancestral reductions in population size,
						 for example, the bottleneck during the post-glacial colonisation.
					</p>
				</div>
			</section>
			<section data-id="frohchart02">
				<div class="col-medium">
					<p>
						To determine if there were more recent reductions we need to look of the proportion of the genome in <strong>long</strong> RoHs. We
						find <Em color='#003f5c'>British</Em> Black-veined white consistently exhibit larger proportions of their genome in large RoHs as well.
						This suggests that the <Em color='#003f5c'>British</Em> Black-veined white underwent additional population reductions or bottlenecks beyond the initial 
						post-glacial event, potentially as late as the nineteenth century.
					</p>
				</div>
			</section>
			</div>
</Scroller>			
{/if}

<Divider/>

<Section>
	<h2>The weight of genetic load</h2>
	<div>
	<p>
		Small or declining populations can harbor individuals with a heavy <strong>genetic load</strong> or a high number of harmful
		mutations or variants in their genes. Many individuals in any given population carry a number of harmful variants,
		however, most of the time, these occur in single copy (i.e. heterozygous) and their effects can be shielded due to a fully functional
		second copy in our genome. However, in small or declining populations, the harmful variants can be inherited from both parents due to inbreeding or chance. 
		In such a homozygous state, there is no respite from the deleterious effects of these variants. Such an increase in genetic load, sometimes called
		the <strong>realised</strong> genetic load, can make a populatiion
		more prone to extinction</p>
	
		<p>We classified the variants in the genomes of museums speciemens as 
			low, moderate or high impact, depending on their predicted impact on gene function. We then compared variants in all classes, in both
			homozygous and heterozygous state, between British and European individuals.
		</p>
	</div>
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
							legend="true"
							colors={['#003f5c', '#ffa600']}
							title={snpTitle}
							mode={["grouped", "barcode"]}

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
						This plot shows the <strong>total</strong> number of low and moderate impact variants (vertical axis) between individuals of 
						<Em color='#003f5c'>British</Em> and <Em color='#ffa600'>European</Em> origin. For total number of such variants,
						<Em color='#ffa600'>European</Em> indiviuals easily outnumber those in <Em color='#003f5c'>British</Em> individuals.
					</p>
				</div>
			</section>
			<section data-id="snpchart02">
				<div class="col-medium">
					<p>
						However, if look at the same class of variants but in <strong>homozygous</strong> state only, the tables are turned. This suggests
						that <Em color='#003f5c'>British</Em> individuals displayed a higher level of <em>realised</em> genetic load, which could also make them more 
						susceptible to extinction.
					</p>
				</div>
			</section>
			<section data-id="snpchart03">
				<div class="col-medium">
					<p>
						<strong>Note</strong>: we did not present the data on high impact variants here as there was no difference for total or homozygous variants in this class.
						This could be partly due to the small number of variants predicted in this class. The full data can be found in the associated <a href="https://doi.org/10.1111/mec.17518">publication</a>.
					</p>
				</div>
			</div>
	</Scroller>			
	{/if}

<Divider/>

<Section>
	<h2>Where do we go from here?</h2>
	<div>
		<p>
			Our genomic analysis on the decline of the Black-viened provides a more nuanced perspective. We suggest that the Black-veined white
			colonized Great Britain around the end of the last glacial period (~12-15000 years ago). It experienced an expected bottleneck during the colonisation
			event but never fully recovered from this. In addition it likely suffered from additional bottlnecks or reductions in population size, some potentially as 
			late at the nineteenth century. Finally, it is possible that accumulation of mildy deleterious variants in homozygous state could have added to its woes prior
			to disappearing altogether in Great Britian.
		</p>
		<p>
			Our analysis provides an example of how we can use more than century-old museum specimens to explore the genomic footprints of extinction. Exploration
			of such signals in extant insects could provide a viable tool for their conservation.
		</p>
		<p>
			On a brighter note, there are now murmurs of a planned reintroduction of the Black-veined white in Britain. A <a href="https://doi.org/10.1101/2024.05.21.595182">systematic and well-planned</a>
			reintroduction could very well see the return of this species to our gardens and meadows.
		</p>
		<br>
		<small>
			<p> 
			<strong>Further Reading:</strong> <br/>
			Pratt, C., 1983. A modern review of the demise of <em>Aporia crataegi</em> L.: 
			the black veined white. The entomologist’s record and journal of variation 95, 161–166
			 <br/><br/>
			 <strong>Developed and edited by:</strong><br/>
			 Saad Arif, Rebecca Whitla, Casper Breuker & Korneel Hens
			 <br/><br/> 
			 <strong>Cover Illustration by:</strong><br/>
			 Lizzie Harper</p>
		</small>
	</div>
	
</Section>

<!-- a place for leaving comments? -->
<!-- <Section>
<Comments identifier="bvw-lastdays-posts" />
</Section> -->

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
