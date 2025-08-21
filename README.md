[![DelivOps banner](https://raw.githubusercontent.com/delivops/.github/main/images/banner.png?raw=true)](https://delivops.com)

# helm-charts

This repository contains Helm charts for deploying various application components.

## Structure

- `charts/app/` - Helm chart for standard applications
- `charts/app-stateful/` - Helm chart for stateful applications
- `charts/cronjob/` - Helm chart for cron jobs

Each chart contains its own `Chart.yaml`, `values.yaml`, and templates for Kubernetes resources.

## Usage

To install a chart:

```sh
helm install <release-name> charts/<chart-name>
```

To customize values:

```sh
helm install <release-name> charts/<chart-name> -f charts/<chart-name>/values.yaml
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/fooBar`)
3. Commit your changes (`git commit -am 'Add some fooBar'`)
4. Push to the branch (`git push origin feature/fooBar`)
5. Create a new Pull Request

## License

MIT
