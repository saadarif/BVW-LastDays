<script>
	import { themes } from '../config.js';
	import { getContext } from 'svelte';

	export let theme = getContext('theme');
</script>

<footer style="color: {themes[theme]['text']}; background-color: {themes[theme]['pale']};">
	<div class="col-wide" data-analytics="footer">
		<a href="https://brookes.ac.uk">
			{#if theme == 'dark'}
			<img
				class="logo-img"
				src="./img/brookes-logo-home.png"
				alt="Oxford Brookes University" />
			{:else}
			<img
				class="logo-img"
				src="./img/brookes-logo-home.png"
				alt="Oxford Brookes University" />
			{/if}
		</a>
		<ul>
			<li><a href="https://saadarif.github.io/" class="link" style="color: {themes[theme]['text']}">Contact Author</a></li>
			<li><a href="https://www.biorxiv.org/content/10.1101/2023.12.19.572305v4.abstract" class="link" style="color: {themes[theme]['text']}">Read the Paper</a></li>
		</ul>
		<hr style="border-top-color: {themes[theme]['muted']}" />
		<div class="license">
			<img
				class="copr-img"
				src="./img/Copyright.png"
				alt="Copyright logog" />
			Copyright Info: All content is copyright of 
			<a
				href="http://www.brookes.ac.uk/"
				class="link"
				target="_blank"
				rel="noopener"
				style="color: {themes[theme]['text']}">Oxford Brookes University</a>, other than the header meadow illustration which is copyright to
				<a
				href="https://lizzieharper.co.uk/"
				class="link"
				target="_blank"
				rel="noopener"
				style="color: {themes[theme]['text']}">Lizzie Harper</a> and used under license.
			
	</div>
</footer>

<style>
	footer {
		padding-bottom: 72px;
		padding-top: 36px;
		font-size: 18px;
	}
	footer a.link {
		-webkit-box-sizing: border-box;
		box-sizing: border-box;
		text-decoration: underline;
		display: inline-block;
	}
	footer a.link:hover {
		text-decoration: none;
	}
	footer a.link:active {
		outline: 3px solid transparent;
		background-color: #fd0;
		-webkit-box-shadow: 0 -2px #fd0, 0 4px #222;
		box-shadow: 0 -2px #fd0, 0 4px #222;
		color: #222;
		text-decoration: none;
	}
	footer hr {
		margin-bottom: 27px;
		margin-top: 36px;
		border: none;
		border-top: 1px solid #777;
	}
	ul {
		padding: 0;
		margin: 0;
	}
	li {
		margin-right: 18px;
		display: inline-block;
	}
	.logo-img {
		margin-bottom: 27px;
	}
	.copr-img {
		margin: 0 0.5rem 0.2rem 0;
		width: 30px;
		height: 30px;
		vertical-align: middle;
	}
	.license {
		vertical-align: top;
	}
	a img:hover {
		cursor: pointer;
	}
</style>