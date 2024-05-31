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

	// DEMO-SPECIFIC IMPORTS
	import bbox from "@turf/bbox";
	import { getData, setColors, getTopo, getBreaks, getColor } from "./utils.js";
	import { colors, units } from "./config.js";
	import { ScatterChart, LineChart, BarChart } from "@onsvisual/svelte-charts";
	import { Map, MapSource, MapLayer, MapTooltip } from "@onsvisual/svelte-maps";

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
	let data = {district: {}, region: {}};
	let metadata = {district: {}, region: {}};
	let geojson;

	// Element bindings
	let map = null; // Bound to mapbox 'map' instance once initialised

	// State
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

	// INITIALISATION CODE
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

<Filler bgimage="./img/BVW_museum1.png"	theme="lightblue" short={true} wide={true} center={false}/>

<Divider/>


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


<Divider/>

<Section>
	<h2>Embedded charts or media</h2>
	<p>
		Below is an embedded chart. It is set to the same width as the column, "medium" (680px), but could also be "narrow" (540px), "wide" (980px) or "full" width. All options are responsive to fit the width of narrow screens.
	</p>
</Section>

{#if data.region.indicators}
<Media
	col="medium"
	caption="Source: ONS mid-year population estimates."
>
	<div class="chart-sml">
		<BarChart
			data={[...data.region.indicators].sort((a, b) => a.pop - b.pop)}
			xKey="pop" yKey="name"
			snapTicks={false}
			xFormatTick={d => (d / 1e6)} xSuffix="m"
			height={350} padding={{top: 0, bottom: 15, left: 140, right: 0}}
			area={false} title="Population by region/nation, 2020"/>
	</div>
</Media>
{/if}

<Divider/>

<Section>
	<h2>Gridded charts or media</h2>
	<p>
		Below is a grid that can contain charts or any other kind of visual media. The grid can fit in a medium, wide or full-width column, and the media width itself can be narrow (min 200px), medium (min 300px), wide (min 500px) or full-width. The grid is responsive, and will re-flow on smaller screens.
	</p>
</Section>

{#if data.region.timeseries && data.region.indicators}
<Media
	col="wide"
	grid="narrow" gap={20}
	caption="Source: ONS mid-year population estimates."
>
	{#each [...data.region.indicators].sort((a, b) => b.pop - a.pop) as region}
	<div class="chart-sml">
		<LineChart
			data={data.region.timeseries}
			xKey="year" yKey="value" zKey="code"
			color="lightgrey"
			lineWidth={1} xTicks={2} snapTicks={false}
			yFormatTick={d => (d / 1e6)} ySuffix="m"
			height={200} padding={{top: 0, bottom: 20, left: 30, right: 15}}
			selected={region.code}
			area={false} title={region.name}/>
	</div>
	{/each}
</Media>
{/if}

<Divider />

<Section>
	<h2>This is a dynamic chart section</h2>
	<p>
		The chart below will respond to the captions as you scroll down. The "Scroller" component is
		set to "splitscreen" mode, which means the captions will be on the left side on larger screens.
	</p>
	<p>
		The interactions are via Javascript functions that are called when each caption scrolls into view.
	</p>
</Section>

<Scroller {threshold} bind:id={id['chart']} splitscreen={true}>
	<div slot="background">
		<figure>
			<div class="col-wide height-full">
				{#if data.district.indicators && metadata.region.lookup}
					<div class="chart">
						<ScatterChart
							height="calc(100vh - 150px)"
							data={data.district.indicators.map(d => ({...d, parent_name: metadata.region.lookup[d.parent].name}))}
							colors={explore ? ['lightgrey'] : colors.cat}
							{xKey} {yKey} {zKey} {rKey} idKey="code" labelKey="name"
							r={[3,10]}
							xScale="log"
							xTicks={[10, 100, 1000, 10000]} xFormatTick={d => d.toLocaleString()}
							xSuffix=" sq.km"
							yFormatTick={d => d.toLocaleString()}
							legend={zKey != null} labels
							select={explore} selected={explore ? selected : null} on:select={doSelect}
							hover {hovered} on:hover={doHover}
							highlighted={explore ? chartHighlighted : []}
							colorSelect="#206095" colorHighlight="#999" overlayFill
							{animation}/>
					</div>
				{/if}
			</div>
		</figure>
	</div>

	<div slot="foreground">
		<section data-id="chart01">
			<div class="col-medium">
				<p>
					This chart shows the <strong>area in square kilometres</strong> of each local authority district in the UK. Each circle represents one district. The scale is logarithmic.
				</p>
			</div>
		</section>
		<section data-id="chart02">
			<div class="col-medium">
				<p>
					The radius of each circle shows the <strong>total population</strong> of the district.
				</p>
			</div>
		</section>
		<section data-id="chart03">
			<div class="col-medium">
				<p>
					The vertical axis shows the <strong>density</strong> of the district in people per hectare.
				</p>
			</div>
		</section>
		<section data-id="chart04">
			<div class="col-medium">
				<p>
					The colour of each circle shows the <strong>part of the country</strong> that the district is within.
				</p>
			</div>
		</section>
		<section data-id="chart05">
			<div class="col-medium">
				<h3>Select a district</h3>
				<p>Use the selection box below or click on the chart to select a district. The chart will also highlight the other districts in the same part of the country.</p>
				{#if geojson}
					<p>
						<!-- svelte-ignore a11y-no-onchange -->
						<select bind:value={selected}>
							<option value={null}>Select one</option>
							{#each geojson.features as place}
								<option value={place.properties.AREACD}>
									{place.properties.AREANM}
								</option>
							{/each}
						</select>
					</p>
				{/if}
			</div>
		</section>
	</div>
</Scroller>

<Divider />

<Section>
	<h2>This is a full-width chart demo</h2>
	<p>
		Below is an example of a media grid where the column with is set to "full". This allows for full width images and charts.
	</p>
	<p>

	</p>
</Section>

<Media
	col="full"
	height={600}
	caption='This is an optional caption for the above chart or media. It can contain HTML code and <a href="#">hyperlinks</a>, and wrap onto multiple lines.'
>
	<div class="chart-full">
		{#if data.district.timeseries}
		<LineChart
			data={data.district.timeseries}
			padding={{left: 50, right: 150, top: 0, bottom: 0}}
			height="500px"
			xKey="year" yKey="value" zKey="code"
			color="lightgrey" lineWidth={1}
			yFormatTick={d => (d/1e6).toFixed(1)} ySuffix="m"
			select {selected} on:select={doSelect}
			hover {hovered} on:hover={doHover}
			highlighted={chartHighlighted}
			colorSelect="#206095" colorHighlight="#999"
			area={false} title="Mid-year population by district, 2001 to 2020"
			labels labelKey="name"/>
		{/if}
	</div>
</Media>

<Divider />

<Section>
	<h2>This is a dynamic map section</h2>
	<p class="mb">
		The map below will respond to the captions as you scroll down. The scroller is not set to splitscreen, so captions are placed over the map on any screen size.
	</p>
</Section>

{#if geojson && data.district.indicators}
<Scroller {threshold} bind:id={id['map']}>
	<div slot="background">
		<figure>
			<div class="col-full height-full">
				<Map style={mapstyle} bind:map interactive={false} location={{bounds: mapbounds.uk}}>
					<MapSource
					  id="lad"
					  type="geojson"
					  data={geojson}
					  promoteId="AREACD"
					  maxzoom={13}>
					  <MapLayer
					  	id="lad-fill"
							idKey="code"
							colorKey={mapKey + "_color"}
					  	data={data.district.indicators}
					  	type="fill"
							select {selected} on:select={doSelect} clickIgnore={!explore}
							hover {hovered} on:hover={doHover}
							highlight highlighted={mapHighlighted}
					  	paint={{
					  		'fill-color': ['case',
					  			['!=', ['feature-state', 'color'], null], ['feature-state', 'color'],
					  			'rgba(255, 255, 255, 0)'
					  		],
					  		'fill-opacity': 0.7
					  	}}>
								<MapTooltip content={
									hovered ? `${metadata.district.lookup[hovered].name}<br/><strong>${data.district.indicators.find(d => d.code == hovered)[mapKey].toLocaleString()} ${units[mapKey]}</strong>` : ''
								}/>
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
					This map shows <strong>population density</strong> by district. Districts are coloured from <Em color={colors.seq[0]}>least dense</Em> to <Em color={colors.seq[4]}>most dense</Em>. You can hover to see the district name and density.
				</p>
			</div>
		</section>
		<section data-id="map02">
			<div class="col-medium">
				<p>
					The map now shows <strong>median age</strong>, from <Em color={colors.seq[0]}>youngest</Em> to <Em color={colors.seq[4]}>oldest</Em>.
				</p>
			</div>
		</section>
		<section data-id="map03">
			<div class="col-medium">
				<!-- This gets the data object for the district with the oldest median age -->
				{#each [[...data.district.indicators].sort((a, b) => b.age_med - a.age_med)[0]] as district}
				<p>
					The map is now zoomed on <Em color={district.age_med_color}>{district.name}</Em>, the district with the oldest median age, {district.age_med} years.
				</p>
				{/each}
			</div>
		</section>
		<section data-id="map04">
			<div class="col-medium">
				<h3>Select a district</h3>
				<p>Use the selection box below or click on the map to select and zoom to a district.</p>
				{#if geojson}
					<p>
						<!-- svelte-ignore a11y-no-onchange -->
						<select bind:value={selected} on:change={() => fitById(selected)}>
							<option value={null}>Select one</option>
							{#each geojson.features as place}
								<option value={place.properties.AREACD}>
									{place.properties.AREANM}
								</option>
							{/each}
						</select>
					</p>
				{/if}
			</div>
		</section>
	</div>
</Scroller>
{/if}

<Divider />

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
