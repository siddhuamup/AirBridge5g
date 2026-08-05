package observability

import (
	"context"
	"fmt"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/exporters/stdout/stdouttrace"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.26.0"
)

type Config struct {
	ServiceName  string
	OTLPEndpoint string
	OTLPInsecure bool
	SampleRatio  float64
}

func Setup(ctx context.Context, cfg Config) (func(context.Context) error, error) {
	if cfg.ServiceName == "" {
		return nil, fmt.Errorf("service name is required")
	}

	exporter, err := newExporter(ctx, cfg)
	if err != nil {
		return nil, err
	}

	sampleRatio := cfg.SampleRatio
	if sampleRatio <= 0 || sampleRatio > 1 {
		sampleRatio = 1
	}

	res, err := resource.New(ctx,
		resource.WithAttributes(semconv.ServiceNameKey.String(cfg.ServiceName)),
	)
	if err != nil {
		return nil, err
	}

	provider := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(res),
		sdktrace.WithSampler(sdktrace.TraceIDRatioBased(sampleRatio)),
	)
	otel.SetTracerProvider(provider)

	return provider.Shutdown, nil
}

func newExporter(ctx context.Context, cfg Config) (sdktrace.SpanExporter, error) {
	if cfg.OTLPEndpoint == "" {
		return stdouttrace.New(stdouttrace.WithPrettyPrint())
	}

	options := []otlptracehttp.Option{
		otlptracehttp.WithEndpoint(cfg.OTLPEndpoint),
	}
	if cfg.OTLPInsecure {
		options = append(options, otlptracehttp.WithInsecure())
	}

	return otlptracehttp.New(ctx, options...)
}
