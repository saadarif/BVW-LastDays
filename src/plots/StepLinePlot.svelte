<script>
    import { onMount, onDestroy } from 'svelte';
    import Chart from 'chart.js/auto';
    import annotationPlugin from 'chartjs-plugin-annotation';
  
    export let datasets = [];
    export let labels = [];
    export let annotationBox = {};
    export let xMin;
    export let xMax;
    export let yMin;
    export let yMax;
    export let borderWidth = 3;
  
    let chart;
    let canvas;
  
    onMount(() => {
      Chart.register(annotationPlugin);
      const ctx = canvas.getContext('2d');
      chart = new Chart(ctx, {
        type: 'line',
        data: {
          labels: labels,
          datasets: datasets.map(dataset => ({
            label: dataset.label,
            data: dataset.data,
            stepped: true,
            borderColor: dataset.borderColor,
            borderWidth: borderWidth, // Adjust the border width to make the step lines thicker
            fill: false
          }))
        },
        options: {
          responsive: true, // Allow the chart to resize responsively
          scales: {
            x: {
              type: 'logarithmic',
              position: 'bottom',
              min: xMin,
              max: xMax,
              title: {
                display: true,
                text: 'Time'
              },
              ticks: {
                callback: function(value, index, values) {
                  return Number(value).toLocaleString();
                }
              }
            },
            y: {
              beginAtZero: false,
              min: yMin,
              max: yMax,
              title: {
                display: true,
                text: 'Ne'
              }
            }
          },
          plugins: {
            annotation: {
              annotations: {
                box1: {
                  type: 'box',
                  xMin: annotationBox.xMin,
                  xMax: annotationBox.xMax,
                  yMin: annotationBox.yMin,
                  yMax: annotationBox.yMax,
                  backgroundColor: 'rgba(101, 33, 171, 0.5)'
                }
              }
            }
          }
        }
      });
    });
  
    onDestroy(() => {
      if (chart) {
        chart.destroy();
      }
    });
  </script>
  
  
  <canvas bind:this={canvas}></canvas>
  
  <style>
    canvas {
      max-width: 100%;
    }
  </style>
  