<script>
    import { onMount } from 'svelte';

    let isPortrait = false;

    // Function to check the orientation
    const checkOrientation = () => {
        isPortrait = window.matchMedia("(orientation: portrait)").matches;
    };

    // Setting up event listeners on mount
    onMount(() => {
        checkOrientation();
        window.addEventListener('orientationchange', checkOrientation);
        window.addEventListener('resize', checkOrientation);

        return () => {
            window.removeEventListener('orientationchange', checkOrientation);
            window.removeEventListener('resize', checkOrientation);
        };
    });
</script>

<style>
    .orientation-prompt {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        display: flex;
        justify-content: center;
        align-items: center;
        background-color: rgba(0, 0, 0, 0.7);
        color: white;
        font-size: 1.5em;
        font-family: "Open Sans", "Helvetica Neue", "Arial", sans-serif;
        text-align: center;
        z-index: 1000;
    }
</style>

{#if isPortrait}
    <div class="orientation-prompt">
        Please rotate your device horizontally for the best viewing experience.
    </div>
{/if}